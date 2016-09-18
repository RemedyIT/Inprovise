# Controller for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'monitor'

class Inprovise::Controller

  class << self

  private

    def controllers
      @controllers ||= Array.new.extend(MonitorMixin)
    end

    def add(ctrl)
      controllers.synchronize do
        controllers << ctrl if ctrl
      end
      ctrl
    end

    def head
      controllers.synchronize do
        return controllers.first
      end
    end

    def shift
      controllers.synchronize do
        return controllers.shift
      end
    end

    def empty?
      controllers.synchronize do
        return controllers.empty?
      end
    end

    def get_value(v)
      begin
        Module.new { def self.eval(s); binding.eval(s); end }.eval(v)
      rescue Exception
        v
      end
    end

    def load_schemes(options)
      # load all specified schemes
      (Array === options[:scheme] ? options[:scheme] : [options[:scheme]]).each {|s| Inprovise::DSL.include(s) }
    end

  public

    def list_scripts(options)
      load_schemes(options)
      $stdout.puts
      $stdout.puts '   PROVISIONING SCRIPTS'
      $stdout.puts '   ===================='
      Inprovise::ScriptIndex.default.scripts.sort.each do |scrname|
        script = Inprovise::ScriptIndex.default.get(scrname)
        if script.description || options[:all]
          script.describe.each {|l| $stdout.puts "   #{l}" }
        end
      end
    end

    def parse_config(cfglist, opts = {})
      cfglist.inject(opts) do |rc, cfg|
        k,v = cfg.split('=')
        k = k.split('.')
        h = rc
        while k.size > 1
          hk = k.shift.to_sym
          raise ArgumentError, "Conflicting config category #{hk}" unless !h.has_key?(hk) || Hash === h[hk]
          h = (h[hk] ||= {})
        end
        h.store(k.shift.to_sym, get_value(v))
        rc
      end
    end

    def run(command, options, *args)
      begin
        case command
        when :add, :remove, :update
          target = args.shift
          if command == :remove
            run_infra_command(command, target, *args)
          else
            tgtcfg = parse_config(options[:config])
            tgtcfg[:credentials] = parse_config(options[:credential]) if target == :node && options.has_key?(:credential)
            run_infra_command(command, target, options, tgtcfg, *args)
          end
        else # :apply, :revert, :validate or :trigger
          load_schemes(options)
          # extract config
          cfg = parse_config(options[:config])
          # get script/action
          sca = args.shift
          run_provisioning_command(command, sca, cfg, *args)
        end
      rescue Exception => e
        cleanup!
        raise e
      end
    end

    def wait!
      ex = nil
      begin
        while !empty?
          head.wait
          shift
        end
      rescue Exception => e
        ex = e
      ensure
        cleanup!
        raise ex if ex
      end
    end

    def cleanup!
      while !empty?
        head.cleanup rescue Exception $stderr.puts $!.backtrace
        shift
      end
    end

    def run_infra_command(cmd, target, *args)
      add(Inprovise::Controller.new).send(:"#{cmd}_#{target}", *args)
      Inprovise::Infrastructure.save
    end

    def run_provisioning_command(command, script, cfg, *targets)
      add(Inprovise::Controller.new).run_provisioning_command(command, script, cfg, *targets)
    end

  end

  def initialize
    @targets = []
    @threads = []
  end

  def wait
    return if @threads.empty?
    Inprovise.log.local('Waiting for controller threads...') if Inprovise.verbosity > 0
    @threads.each { |t| t.join }
  end

  def cleanup
    return if @targets.empty?
    Inprovise.log.local('Disconnecting...') if Inprovise.verbosity > 0
    @targets.each {|tgt| tgt.disconnect! }
    Inprovise.log.local('Done!') if Inprovise.verbosity > 0
  end

  def run_provisioning_command(command, cmdtgt, cmdcfg, *names)
    # get intended infrastructure targets/config tuples
    targets = get_targets(*names)
    # create runner/config for each target/config
    runners = targets.map do |tgt, tgtcfg|
      @targets << tgt
      [
        if command == :trigger
          Inprovise::TriggerRunner.new(tgt, cmdtgt, Inprovise.skip_dependencies)
        else
          Inprovise::ScriptRunner.new(tgt, Inprovise::ScriptIndex.default.get(cmdtgt), Inprovise.skip_dependencies)
        end,
        tgtcfg
      ]
    end
    # execute runners
    if Inprovise.sequential
      runners.each {|runner, tgtcfg| exec(runner, command, tgtcfg.merge(cmdcfg)) }
    else
      @threads = runners.map {|runner, tgtcfg| Thread.new { exec(runner, command, tgtcfg.merge(cmdcfg)) } }
    end
  end

  def add_node(options, nodecfg, name)
    nodecfg.merge!({ host: options[:address] })
    @targets << (node = Inprovise::Infrastructure::Node.new(name, nodecfg))

    Inprovise.log.local("Adding #{node}")

    Inprovise::Sniffer.run_sniffers_for(node) if options[:sniff]

    options[:group].each do |g|
      grp = Inprovise::Infrastructure.find(g)
      raise ArgumentError, "Unknown group #{g}" unless grp
      node.add_to(grp)
    end
  end

  def remove_node(*names)
    names.each do |name|
      node = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid node #{name}" unless node && node.is_a?(Inprovise::Infrastructure::Node)

      Inprovise.log.local("Removing #{node}")

      Inprovise::Infrastructure.deregister(name)
    end
  end

  def update_node(options, nodecfg, *names)
    @targets = names.collect do |name|
      tgt = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Unknown target [#{name}]" unless tgt
      tgt.targets
    end.flatten.uniq
    if Inprovise.sequential || (!options[:sniff]) || @targets.size == 1
      @targets.each {|tgt| run_node_update(tgt, nodecfg.dup, options) }
    else
      threads = @targets.map {|tgt| Thread.new { run_node_update(tgt, nodecfg.dup, options) } }
      threads.each {|t| t.join }
    end
  end

  def add_group(options, grpcfg, name)
    options[:target].each {|t| raise ArgumentError, "Unknown target [#{t}]" unless Inprovise::Infrastructure.find(t) }
    grp = Inprovise::Infrastructure::Group.new(name, grpcfg)

    Inprovise.log.local("Adding #{grp}")

    options[:target].each do |t|
      tgt = Inprovise::Infrastructure.find(t)
      raise ArgumentError, "Unknown target #{t}" unless tgt
      tgt.add_to(grp)
    end
  end

  def remove_group(*names)
    names.each do |name|
      grp = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid group #{name}" unless grp && grp.is_a?(Inprovise::Infrastructure::Group)

      Inprovise.log.local("Removing #{grp}")

      Inprovise::Infrastructure.deregister(name)
    end
  end

  def update_group(options, grpcfg, *names)
    groups = names.collect do |name|
      tgt = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid group #{name}" unless tgt && tgt.is_a?(Inprovise::Infrastructure::Group)
      tgt
    end
    grp_tgts = options[:target].collect do |tnm|
      tgt = Inprovise::Infrastructure.find(tnm)
      raise ArgumentError, "Unknown target #{tnm}" unless tgt
      tgt
    end
    groups.each do |grp|
      Inprovise.log.local("Updating #{grp}")

      grp.config.clear if options[:reset]
      grp.config.merge!(grpcfg)
      grp_tgts.each {|gt| gt.add_to(grp) }
    end
  end

  private

  def get_targets(*names)
    names.inject({}) do |hsh, name|
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
  end

  def exec(runner, command, cfg)
    if Inprovise.demonstrate
      runner.demonstrate(command, cfg)
    else
      runner.execute(command, cfg)
    end
  end

  def run_node_update(node, nodecfg, options)
    Inprovise.log.local("Updating #{node}")

    if options[:reset]
      # preserve :host
      nodecfg[:host] = node.get(:host) if node.get(:host)
      # preserve :user if no new user specified
      nodecfg[:user] = node.get(:user) if node.get(:user) && !nodecfg.has_key?(:user)
      # preserve sniffed attributes when not running sniffers now
      unless options[:sniff]
        nodecfg[:attributes] = node.get(:attributes)
      end
      # clear the node config
      node.config.clear
    end
    node.config.merge!(nodecfg) # merge new + preserved config
    # force update of user if specified
    node.prepare_connection_for_user!(nodecfg[:user]) if nodecfg[:user]
    Inprovise::Sniffer.run_sniffers_for(node) if options[:sniff]
    options[:group].each do |g|
      grp = Inprovise::Infrastructure.find(g)
      raise ArgumentError, "Unknown group #{g}" unless grp
      node.add_to(grp)
    end
  end

end
