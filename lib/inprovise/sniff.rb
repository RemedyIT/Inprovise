# Sniffer main module for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

module Inprovise::Sniffer

  class << self

    def sniffers
      @sniffers ||= []
    end

    def add_sniffer(sniffer)
      raise ArgumentError, 'Invalid sniffer added.' unless sniffer.respond_to?(:id) && sniffer.respond_to?(:sniff_for)
      sniffers << sniffer
    end

    def run_sniffers_for(context)
      sniffers.inject({}) {|attr, sniffer| attr[sniffer.id.to_sym] = sniffer.sniff_for(context); attr }
    end

  end

  module SnifferMixin

    def self.included(mod)
      sniffer_id = mod.name.split('::').last.sub(/Sniffer\Z/,'')
      sniffer_id.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      sniffer_id.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      sniffer_id.tr!('-', '_')
      sniffer_id.downcase!
      mod.class_eval %Q{
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def self.id
          '#{sniffer_id}'
        end

        def self.sniff_for(context)
          context.log.set_task("Sniff{#{sniffer_id}}")
          new(context).run
        end

        def run
          raise 'Unimplemented sniffer'
        end
      }
      Inprovise::Sniffer.add_sniffer(mod)
    end

  end

end

require_relative './sniffers/platform.rb'
