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
        run_node_cmd(command, options, args.shift)
      when :group
      else
      end
    end
  end

  private

  def run_node_cmd(command, options, name)
    case command
    when :add
      opts = options[:config].inject({ host: options[:address] }) do |rc, cfg|
        rc.store(*cfg.split('='))
        rc
      end
      node = Inprovise::Infrastructure::Node.new(name, opts)
      log = Inprovise::Logger.new(node, nil)
      exec = Inprovise::ExecutionContext.new(node, log)
      log.stdout('sniffing', true)
      node.set(:attributes, Inprovise::Sniffer.run_sniffers_for(exec))
    when :remove
      Inprovise::Infrastructure.deregister(name)
    end
    Inprovise::Infrastructure.save
  end

end
