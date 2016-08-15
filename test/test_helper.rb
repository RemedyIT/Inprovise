# Test helper for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

gem 'minitest'
require 'minitest/autorun'
require 'mocha/setup'
require_relative '../lib/inprovise'

def reset_script_index!
  Inprovise::ScriptIndex.default.clear!
end

def reset_infrastructure!
  Inprovise::Infrastructure.reset
end

# patch Infrastructure#load and #save to do nothing
module Inprovise::Infrastructure
  class << self
    def load
      # noop
    end
    def save
      # noop
    end

    # add reset
    def reset
      targets.synchronize do
        targets.clear
      end
    end
  end
end
