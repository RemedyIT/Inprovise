# Main loader for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'rubygems'
require 'colored'

module Inprovise

  VERSION = '0.1.1'
  INFRA_FILE = 'infra.json'

  class << self
    def verbosity
      @verbose ||= 0
    end

    def verbosity=(val)
      @verbose = val.to_i
    end

    def infra
      @infra ||= (ENV['INPROVISE_INFRA'] || find_infra)
    end

    def root
      @root ||= File.dirname(infra)
    end

    private

    def find_infra
      curpath = File.expand_path('.')
      begin
        # check if this is where the infra file lives
        if File.file?(File.join(curpath, Inprovise::INFRA_FILE))
          return File.join(curpath, Inprovise::INFRA_FILE)
        end
        # not found yet, move one dir up until we reach the root
        curpath = File.expand_path(File.join(curpath, '..'))
      end while !(curpath =~ /^(#{File::SEPARATOR}|.:#{File::SEPARATOR})$/)
      INFRA_FILE
    end
  end

end

require_relative './inprovise/logger.rb'
require_relative './inprovise/local_file.rb'
require_relative './inprovise/remote_file.rb'
require_relative './inprovise/execution_context.rb'
require_relative './inprovise/infra.rb'
require_relative './inprovise/sniff.rb'
require_relative './inprovise/cli.rb'
