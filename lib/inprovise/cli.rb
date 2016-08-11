# CLI for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'gli'

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

  desc 'Don\'t run tasks in parrallel across nodes.'
  switch [:sequential], {negatable: false}

  desc 'Don\'t validate and run dependencies.'
  switch [:'skip-dependencies'], {negatable: false}

  require_relative './cli/node'
  require_relative './cli/group'
  require_relative './cli/provision'

  pre do |global,command,options,args|
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    Inprovise.verbosity = global[:verbose] || 0
    Inprovise::Infrastructure.load
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
    if Inprovise.verbosity > 0
      $stderr.puts "#{exception}\n#{exception.backtrace.join("\n")}"
    end
    exit 1
  end

end
