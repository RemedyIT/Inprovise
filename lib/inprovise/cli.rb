# CLI for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'gli'
require 'fileutils'

class Inprovise::Cli

  class << self
    include GLI::App
  end


  program_desc 'CLI for Inprovise'

  version Inprovise::VERSION

  subcommand_option_handling :normal
  arguments :strict
  sort_help :manually

  desc 'Don\'t actually run any commands on the group, just pretend.'
  switch [:n,:'dry-run'], {negatable: false}

  desc 'Increase verbosity, useful for debugging.'
  flag [:v, :verbose], :arg_name => 'LEVEL', :default_value => 0, :type => Integer

  desc 'Show exception backtraces on exit.'
  switch [:x, :'show-backtrace'], {negatable: false}

  desc 'Don\'t run tasks in parrallel across nodes.'
  switch [:sequential], {negatable: false}

  desc 'Don\'t validate and run dependencies.'
  switch [:'skip-dependencies'], {negatable: false}

  require_relative './cli/node'
  require_relative './cli/group'
  require_relative './cli/provision'

  desc 'Initialize Inprovise project.'
  command :init do |cinit|
    cinit.action do |global,options,args|
      raise RuntimeError, 'Cannot initialize existing project directory.' if File.exists?(Inprovise::INFRA_FILE)
      raise RuntimeError, "Default scheme #{Inprovise.default_scheme} already exists." if File.exists?(Inprovise.default_scheme)
      begin
        Inprovise::Infrastructure.init(Inprovise::INFRA_FILE)
        path = Inprovise::Template.new(File.join(File.dirname(__FILE__),'template','inprovise.rb.erb')).render_to_tempfile
        FileUtils.mv(path, Inprovise.default_scheme)
      rescue
        File.delete(Inprovise::INFRA_FILE) if File.exists?(Inprovise::INFRA_FILE)
        File.delete(Inprovise.default_scheme) if File.exists?(Inprovise.default_scheme)
        raise
      end
    end
  end

  pre do |global,command,options,args|
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    Inprovise.verbosity = global[:verbose] || 0
    Inprovise.show_backtrace = global[:'show-backtrace']
    Inprovise.sequential = global[:sequential]
    Inprovise.demonstrate = global[:demonstrate]
    Inprovise.skip_dependencies = global[:'skip-dependencies']
    unless command.name == :init
      if File.readable?(File.join(Inprovise.root, Inprovise::RC_FILE))
        Inprovise.log.local("Loading #{Inprovise::RC_FILE}") if Inprovise.verbosity > 1
        load File.join(Inprovise.root, Inprovise::RC_FILE)
      end

      Inprovise::Infrastructure.load
    end
    true
  end

  post do |global,command,options,args|
    # Post logic here
    # Use skips_post before a command to skip this
    # block on that command only
  end

  on_error do |exception|
    # Error logic here
    # return false to skip default error handling
    $stderr.puts "ERROR: #{exception.message}".red
    if Inprovise.show_backtrace
      $stderr.puts "#{exception}\n#{exception.backtrace.join("\n")}"
    end
    exit 1
  end

  def self.show_target(tgt, details=false)
    $stdout.puts "   #{tgt.to_s}"
    if details
      $stdout.puts "   \t"+JSON.pretty_generate(tgt.config).split("\n").join("\n   \t")
    end
  end

end
