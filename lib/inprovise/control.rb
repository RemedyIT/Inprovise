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
          case args.shift
          when :node
            run_node_command(command, options, *args)
          when :group
            run_group_command(command, options, *args)
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

    def run_node_command(cmd, options, *names)
      add(Inprovise::Controller.new).send(:"#{cmd}_node", options, *names)
      Inprovise::Infrastructure.save
    end

    def run_group_command(cmd, options, *names)
      add(Inprovise::Controller.new).send(:"#{cmd}_group", options, *names)
      Inprovise::Infrastructure.save
    end

    def run_provisioning_command(command, script, opts, *targets)
      add(Inprovise::Controller.new).run_provisioning_command(command, script, opts, *targets)
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

  def run_provisioning_command(command, cmdtgt, opts, *names)
    # get intended infrastructure targets/config tuples
    targets = get_targets(*names)
    # create runner/config for each target/config
    runners = targets.map do |tgt, cfg|
      @targets << tgt
      [
        if command == :trigger
          Inprovise::TriggerRunner.new(tgt, cmdtgt)
        else
          Inprovise::ScriptRunner.new(tgt, Inprovise::ScriptIndex.default.get(cmdtgt), Inprovise.skip_dependencies)
        end,
        cfg
      ]
    end
    # execute runners
    if Inprovise.sequential
      runners.each {|runner, cfg| exec(runner, command, cfg.merge(opts)) }
    else
      @threads = runners.map {|runner, cfg| Thread.new { exec(runner, command, cfg.merge(opts)) } }
    end
  end

  def add_node(options, *names)
    opts = self.class.parse_config(options[:config], { host: options[:address] })
    opts[:credentials] = self.class.parse_config(options[:credential])
    @targets << (node = Inprovise::Infrastructure::Node.new(names.first, opts))

    Inprovise.log.local("Adding #{node}")

    Inprovise::Sniffer.run_sniffers_for(node) if options[:sniff]

    options[:group].each do |g|
      grp = Inprovise::Infrastructure.find(g)
      raise ArgumentError, "Unknown group #{g}" unless grp
      node.add_to(grp)
    end
  end

  def remove_node(options, *names)
    names.each do |name|
      node = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid node #{name}" unless node && node.is_a?(Inprovise::Infrastructure::Node)

      Inprovise.log.local("Removing #{node}")

      Inprovise::Infrastructure.deregister(name)
    end
  end

  def update_node(options, *names)
    @targets = names.collect do |name|
      tgt = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Unknown target [#{name}]" unless tgt
      tgt.targets
    end.flatten.uniq
    opts = self.class.parse_config(options[:config])
    opts[:credentials] = self.class.parse_config(options[:credential])
    if Inprovise.sequential || (!options[:sniff]) || @targets.size == 1
      @targets.each {|tgt| run_target_update(tgt, opts.dup, options) }
    else
      threads = @targets.map {|tgt| Thread.new { run_target_update(tgt, opts.dup, options) } }
      threads.each {|t| t.join }
    end
  end

  def add_group(options, *names)
    options[:target].each {|t| raise ArgumentError, "Unknown target [#{t}]" unless Inprovise::Infrastructure.find(t) }
    opts = self.class.parse_config(options[:config])
    grp = Inprovise::Infrastructure::Group.new(names.first, opts, options[:target])

    Inprovise.log.local("Adding #{grp}")

    options[:target].each do |t|
      tgt = Inprovise::Infrastructure.find(t)
      raise ArgumentError, "Unknown target #{t}" unless tgt
      tgt.add_to(grp)
    end
  end

  def remove_group(options, *names)
    names.each do |name|
      grp = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid group #{name}" unless grp && grp.is_a?(Inprovise::Infrastructure::Group)

      Inprovise.log.local("Removing #{grp}")

      Inprovise::Infrastructure.deregister(name)
    end
  end

  def update_group(options, *names)
    groups = names.collect do |name|
      tgt = Inprovise::Infrastructure.find(name)
      raise ArgumentError, "Invalid group #{name}" unless tgt && tgt.is_a?(Inprovise::Infrastructure::Group)
      tgt
    end
    opts = self.class.parse_config(options[:config])
    grp_tgts = options[:target].collect do |tnm|
      tgt = Inprovise::Infrastructure.find(tnm)
      raise ArgumentError, "Unknown target #{tnm}" unless tgt
      tgt
    end
    groups.each do |grp|
      Inprovise.log.local("Updating #{grp}")

      grp.config.clear if options[:reset]
      grp.config.merge!(opts)
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

  def exec(runner, command, opts)
    if Inprovise.demonstrate
      runner.demonstrate(command, opts)
    else
      runner.execute(command, opts)
    end
  end

  def run_target_update(tgt, tgt_opts, options)
    Inprovise.log.local("Updating #{tgt}")

    if options[:reset]
      # preserve :host
      tgt_opts[:host] = tgt.get(:host) if tgt.get(:host)
      # preserve :user if no new user specified
      tgt_opts[:user] = tgt.get(:user) if tgt.get(:user) && !tgt_opts.has_key?(:user)
      # preserve sniffed attributes when not running sniffers now
      unless options[:sniff]
        tgt_opts[:attributes] = tgt.get(:attributes)
      end
      # clear the target config
      tgt.config.clear
    end
    tgt.config.merge!(tgt_opts) # merge new + preserved config
    # force update of user if specified
    tgt.prepare_connection_for_user!(tgt_opts[:user]) if tgt_opts[:user]
    Inprovise::Sniffer.run_sniffers_for(tgt) if options[:sniff]
    options[:group].each do |g|
      grp = Inprovise::Infrastructure.find(g)
      raise ArgumentError, "Unknown group #{g}" unless grp
      tgt.add_to(grp)
    end
  end

end
