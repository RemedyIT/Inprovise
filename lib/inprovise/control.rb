# Controller for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Controller

  def initialize(options={})
    @sequential = options[:sequential]
    @demonstrate = options[:demonstrate]
    @skip_dependencies = options[:'skip-dependencies'] || false
    @targets = []
  end

  def run(command, options, *args)
    ex = nil
    begin
      case command
      when :add, :remove, :update
        case args.shift
        when :node
          run_node_cmd(command, options, *args)
        when :group
          run_group_cmd(command, options, *args)
        end
      else # :apply, :revert, :validate or :trigger
        run_provisioning_command(command, options, *args)
      end
    rescue Exception => e
      ex = e
    ensure
      cleanup
      raise ex if ex
    end
  end

  def cleanup
    return if @targets.empty?
    Inprovise.log.local('Disconnecting...') if Inprovise.verbosity > 0
    @targets.each(&:disconnect)
    Inprovise.log.local('Done!') if Inprovise.verbosity > 0
  end

  private

  def run_provisioning_command(command, options, *args)
    # load all specified schemes
    (Array === options[:scheme] ? options[:scheme] : [options[:scheme]]).each {|s| Inprovise::DSL.include(s) }
    # get command target and intended infrastructure targets/config tuples
    cmdtgt = args.shift
    targets = args.inject({}) do |hsh, name|
      tgt = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Unknown target [#{name}]" unless tgt
      tgt.targets_with_config.each do |tgt_, cfg|
        if hsh.has_key?(tgt_)
          hsh[tgt_].merge!(cfg)
        else
          hsh[tgt_] = cfg
        end
      end
      hsh
    end
    # create runner/config for each target/config
    runners = targets.map do |tgt, cfg|
      @targets << tgt
      [
        if command == :trigger
          Inprovise::TriggerRunner.new(tgt, cmdtgt)
        else
          script = Inprovise::ScriptIndex.default.get(cmdtgt)
          Inprovise::ScriptRunner.new(tgt, script, @skip_dependencies)
        end,
        cfg
      ]
    end
    # extract options
    opts = options[:config].inject({}) do |rc, cfg|
      k,v = cfg.split('=')
      rc.store(k.to_sym, get_value(v))
      rc
    end
    # execute runners
    if @sequential
      runners.each {|runner, cfg| exec(runner, command, cfg.merge(opts)) }
    else
      threads = runners.map {|runner, cfg| Thread.new { exec(runner, command, cfg.merge(opts)) } }
      threads.each {|t| t.join }
    end
  end

  def exec(runner, command, opts)
    if @demonstrate
      runner.demonstrate(command, opts)
    else
      runner.execute(command, opts)
    end
  end

  def get_value(v)
    Module.new { def self.eval(s); binding.eval(s); end }.eval(v) rescue v
  end

  def add_pubkey_script(node, pubkey_path)
    Inprovise::DSL.script("pubkey-#{node.name}") do
      apply do
        local_pubkey = local(pubkey_path)
        remote_pubkey = "inprovise-upload-#{local_pubkey.hash}"
        local_pubkey.copy_to(remote(remote_pubkey))
        sudo("cat #{remote_pubkey} >> ${HOME}/.ssh/authorized_keys")
        remote(remote_pubkey).delete!
        remote('${HOME}/.ssh/authorized_keys').set_permissions(644)
      end
    end
  end

  def run_node_cmd(command, options, *names)
    case command
    when :add
      opts = options[:config].inject({ host: options[:address] }) do |rc, cfg|
        k,v = cfg.split('=')
        rc.store(k.to_sym, get_value(v))
        rc
      end
      @targets << (node = Inprovise::Infrastructure::Node.new(names.first, opts))

      Inprovise.log.local("Adding #{node.to_s}")

      log = Inprovise::Logger.new(node, nil)
      exec = Inprovise::ExecutionContext.new(node, log)
      #log.stdout('sniffing', true)
      node.set(:attributes, Inprovise::Sniffer.run_sniffers_for(exec))
      options[:group].each do |g|
        grp = Inprovise::Infrastructure.find(g)
        raise ArgumentError, "Unknown group #{g}" unless grp
        node.add_to(grp)
      end
      if options[:'public-key']
        pubkey_path = options[:'public-key']
        pubkey_path = File.expand_path(pubkey_path, Inprovise.root)
        raise ArgumentError, "Invalid public key file [#{pubkey_path}]" unless File.file?(pubkey_path) && File.readable?(pubkey_path)
        script = add_pubkey_script(node, pubkey_path)
        Inprovise::ScriptRunner.new(node, script, true).execute(:apply)
      end
    when :remove
      names.each do |name|
        node = Inprovise::Infrastructure.find(name)
        raise ArgumentError, "Invalid node #{name}" unless node && node.is_a?(Inprovise::Infrastructure::Node)

        Inprovise.log.local("Removing #{node.to_s}")

        Inprovise::Infrastructure.deregister(name)
      end
    when :update
      @targets = names.collect do |name|
        tgt = Inprovise::Infrastructure.find(name)
        raise ArgumentError, "Unknown target [#{name}]" unless tgt
        tgt.targets
      end.flatten.uniq
      opts = options[:config].inject({}) do |rc, cfg|
        k,v = cfg.split('=')
        rc.store(k.to_sym, get_value(v))
        rc
      end
      if @sequential || (!options[:sniff]) || @targets.size == 1
        @targets.each {|tgt| run_target_update(tgt, opts.dup, options) }
      else
        threads = @targets.map {|tgt| Thread.new { run_target_update(tgt, opts.dup, options) } }
        threads.each {|t| t.join }
      end
    end
    Inprovise::Infrastructure.save
  end

  def run_target_update(tgt, tgt_opts, options)
    Inprovise.log.local("Updating #{tgt.to_s}")

    log = Inprovise::Logger.new(tgt, nil)
    exec = Inprovise::ExecutionContext.new(tgt, log)
    if options[:reset]
      # preserve :host
      tgt_opts[:host] = tgt.get(:host) if tgt.get(:host)
      # preserve sniffed attributes when not running sniffers now
      unless options[:sniff]
        tgt_opts[:attributes] = tgt.get(:attributes)
      end
      # clear the target config
      tgt.config.clear
    end
    tgt.config.merge!(tgt_opts) # merge new + preserved config
    tgt.set(:attributes, (tgt.get(:attributes) || {}).merge(Inprovise::Sniffer.run_sniffers_for(exec))) if options[:sniff]
    options[:group].each do |g|
      grp = Inprovise::Infrastructure.find(g)
      raise ArgumentError, "Unknown group #{g}" unless grp
      tgt.add_to(grp)
    end
    if options[:'public-key']
      pubkey_path = options[:'public-key']
      pubkey_path = File.expand_path(pubkey_path, Inprovise.root)
      raise ArgumentError, "Invalid public key file [#{pubkey_path}]" unless File.file?(pubkey_path) && File.readable?(pubkey_path)
      script = add_pubkey_script(tgt, pubkey_path)
      Inprovise::ScriptRunner.new(tgt, script, true).execute(:apply)
    end
  end

  def run_group_cmd(command, options, *names)
    case command
    when :add
      options[:target].each {|t| raise ArgumentError, "Unknown target [#{t}]" unless Inprovise::Infrastructure.find(t) }
      opts = options[:config].inject({}) do |rc, cfg|
        k,v = cfg.split('=')
        rc.store(k.to_sym, get_value(v))
        rc
      end
      grp = Inprovise::Infrastructure::Group.new(names.first, opts, options[:target])

      Inprovise.log.local("Adding #{grp.to_s}")

      options[:target].each do |t|
        tgt = Inprovise::Infrastructure.find(t)
        raise ArgumentError, "Unknown target #{t}" unless tgt
        tgt.add_to(grp)
      end
    when :remove
      names.each do |name|
        grp = Inprovise::Infrastructure.find(name)
        raise ArgumentError, "Invalid group #{name}" unless grp && grp.is_a?(Inprovise::Infrastructure::Group)

        Inprovise.log.local("Removing #{grp.to_s}")

        Inprovise::Infrastructure.deregister(name)
      end
    when :update
      groups = names.collect do |name|
        grp = Inprovise::Infrastructure.find(name)
        raise ArgumentError, "Invalid group #{name}" unless grp && grp.is_a?(Inprovise::Infrastructure::Group)
        grp
      end
      opts = options[:config].inject({}) do |rc, cfg|
        k,v = cfg.split('=')
        rc.store(k.to_sym, get_value(v))
        rc
      end
      grp_tgts = options[:target].collect do |t|
                   tgt = Inprovise::Infrastructure.find(t)
                   raise ArgumentError, "Unknown target #{t}" unless tgt
                   tgt
                 end
      groups.each do |grp|
        Inprovise.log.local("Updating #{grp.to_s}")

        grp.config.clear if options[:reset]
        grp.config.merge!(opts)
        grp_tgts.each {|tgt| tgt.add_to(grp) }
      end
    end
    Inprovise::Infrastructure.save
  end

end
