# Controller for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Controller

  def initialize(options={})
    @sequential = options[:sequential]
    @demonstrate = options[:demonstrate]
    #@skip_dependancies = options[:'skip-dependancies'] || false
    @targets = []
  end

  def run(command, options, *args)
    case command
    when :add, :remove
      case args.shift
      when :node
        run_node_cmd(command, options, *args)
      when :group
        run_group_cmd(command, options, *args)
      else
      end
    end
  end

  private

  def get_value(v)
    Module.new { def self.eval(s); binding.eval(s); end }.eval(v) rescue v
  end

  def run_node_cmd(command, options, *names)
    case command
    when :add
      opts = options[:config].inject({ host: options[:address] }) do |rc, cfg|
        k,v = cfg.split('=')
        rc.store(k.to_sym, get_value(v))
        rc
      end
      node = Inprovise::Infrastructure::Node.new(names.first, opts)
      log = Inprovise::Logger.new(node, nil)
      exec = Inprovise::ExecutionContext.new(node, log)
      #log.stdout('sniffing', true)
      node.set(:attributes, Inprovise::Sniffer.run_sniffers_for(exec))
      options[:group].each do |g|
        grp = Inprovise::Infrastructure.find(g)
        raise ArgumentError, "Unknown group #{g}" unless grp
        node.add_to(grp)
      end
    when :remove
      names.each {|name| Inprovise::Infrastructure.deregister(name) }
    end
    Inprovise::Infrastructure.save
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
    when :remove
      names.each {|name| Inprovise::Infrastructure.deregister(name) }
    end
    Inprovise::Infrastructure.save
  end

end
