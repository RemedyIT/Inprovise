# Main loader for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'rubygems'
require 'colored'

module Inprovise

  VERSION = '0.1.1'
  INFRA_FILE = 'infra.json'
  RC_FILE = 'rigrc'
  DEFAULT_SCHEME = 'inprovise.rb'

  class << self
    def verbosity
      @verbose ||= 0
    end

    def verbosity=(val)
      @verbose = val.to_i
    end

    def show_backtrace
      @show_backtrace ||= false
    end

    def show_backtrace=(f)
      @show_backtrace = (f == true)
    end

    def sequential
      @sequential ||= false
    end

    def sequential=(f)
      @sequential = (f == true)
    end

    def demonstrate
      @demonstrate ||= false
    end

    def demonstrate=(f)
      @demonstrate = (f == true)
    end

    def skip_dependencies
      @skip_dependencies ||= false
    end

    def skip_dependencies=(f)
      @skip_dependencies = (f == true)
    end

    def infra
      @infra ||= (ENV['INPROVISE_INFRA'] || find_infra)
    end

    def root
      @root ||= File.dirname(infra)
    end

    def default_scheme
      ENV['INPROVISE_SCHEME'] || Inprovise::DEFAULT_SCHEME
    end

    def schemes
      @schemes ||= []
    end

    def loaded?(scheme)
      schemes.include?(File.expand_path(scheme, root))
    end

    def log
      @log ||= Inprovise::Logger.new('Local', 'cli')
    end

    def add_script(script)
      yield(script) if block_given?
      Inprovise::ScriptIndex.default.add(script)
      script
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

  module DSL

    def self.singleton_class
      class << self; self; end
    end unless self.respond_to?(:singleton_class)

    singleton_class.class_eval do
      def dsl_define(*args, &block)
        Inprovise::DSL.singleton_class.class_eval(*args, &block)
      end
    end

    dsl_define do
      def include(path)
        path = File.expand_path(path, Inprovise.root)
        unless Inprovise.schemes.include?(path)
          Inprovise.schemes << path
          Inprovise.log.local("Loading provisioning scheme #{path}") if Inprovise.verbosity > 0
          Inprovise::DSL.module_eval(File.read(path), path)
        end
      end
    end

  end

end

require_relative './inprovise/logger'
require_relative './inprovise/cmd_channel'
require_relative './inprovise/cmd_helper'
require_relative './inprovise/script'
require_relative './inprovise/script_index'
require_relative './inprovise/local_file'
require_relative './inprovise/remote_file'
require_relative './inprovise/script_runner'
require_relative './inprovise/trigger_runner'
require_relative './inprovise/resolver'
require_relative './inprovise/template'
require_relative './inprovise/execution_context'
require_relative './inprovise/infra'
require_relative './inprovise/sniff'
require_relative './inprovise/control'
require_relative './inprovise/cli'
