# Sniffer main module for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

module Inprovise::Sniffer

  ROOT_SCRIPT = 'sniffers'

  class << self

    def sniffers
      @sniffers ||= Inprovise::ScriptIndex.new('sniffers')
    end

    def add_sniffer(name, &definition)
      Inprovise.log.local("Adding sniffer script #{name}") if Inprovise.verbosity > 2
      script = Inprovise::Script.new(name)
      Inprovise::Script::DSL.new(script).instance_eval(&definition) if block_given?
      sniffers.add(script)
      script
    end
    private :add_sniffer

    def sniffer(name, &definition)
      script = add_sniffer("sniff[#{name}]", &definition)
      sniffers.get(ROOT_SCRIPT).triggers(script.name)
    end

    def run_sniffers_for(node)
      node.config[:attributes] ||= {}
      runner = Inprovise::ScriptRunner.new(node, 'sniffers')
      runner.set_index(@sniffers)
      runner.execute(:apply)
    end

  end

  # add root sniffer script
  # (doesn't do anything by itself except provide a container triggering all specific sniffers)
  add_sniffer(ROOT_SCRIPT)

end

require_relative './sniffer/platform.rb'
