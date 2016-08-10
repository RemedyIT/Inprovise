# Infrastructure basics for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'json'
require 'monitor'

module Inprovise::Infrastructure

  # setup JSON parameters
  JSON.load_default_options[:symbolize_names] = true
  JSON.create_id = :json_class

  class << self
    def targets
      @targets ||= Hash.new.extend(MonitorMixin)
    end
    private :targets

    def find(name)
      return name if name.is_a?(Target)
      targets.synchronize do
        return targets[name]
      end
    end

    def names
      targets.synchronize do
        targets.keys.sort
      end
    end

    def list(type=Target)
      targets.synchronize do
        targets.values.select {|t| type === t}
      end
    end

    def register(tgt)
      targets.synchronize do
        targets[tgt.name] = tgt
      end
    end

    def deregister(tgt)
      targets.synchronize do
        raise ArgumentError, "Invalid infrastructure target [#{tgt.to_s}]" unless targets.delete(Target === tgt ? tgt.name : tgt.to_s)
        targets.each_value {|t| t.remove_target(tgt) }
      end
    end

    def save
      targets.synchronize do
        data = []
        targets.each_value {|t| t.is_a?(Node) ? data.insert(0,t) : data.push(t) }
        File.open(Inprovise.infra, 'w') {|f| f << JSON.pretty_generate(data) }
      end
    end

    def load
      targets.synchronize do
        JSON.load(IO.read(Inprovise.infra)) if File.readable?(Inprovise.infra)
      end
    end
  end

  class Target
    attr_reader :name, :config

    def initialize(name, config = {})
      @name = name
      @config = config
      Inprovise::Infrastructure.register(self)
    end

    def get(option)
      config[option]
    end

    def set(option, value)
      config[option.to_sym] = value
    end

    def add_to(grp)
      grp.add_target(self)
    end

    def remove_from(grp)
      grp.remove_target(self)
    end

    def add_target(tgt)
      $stderr.puts "ERROR: cannot add #{tgt.to_s} to #{self.to_s}"
    end

    def remove_target(tgt)
      # ignore
    end

    def targets
      [self]
    end
  end

end

require_relative './node.rb'
require_relative './group.rb'
