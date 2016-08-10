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

  desc 'Don\'t actually run any commands on the group, just pretend.'
  switch [:n,:'dry-run'], {negatable: false}

  #desc 'Path to a provisioning scheme to load, if none specified loads ./inprovise.rb.'
  #default_value 'the default'
  #arg_name 'FILE'
  #flag [:s,:scheme]

  desc 'Increase verbosity, useful for debugging.'
  flag [:v, :verbose], :arg_name => 'LEVEL', :default_value => 0, :type => Integer

  desc 'Don\'t run tasks in parrallel across nodes.'
  switch [:sequential], {negatable: false}

  # class_option :throw,       :type => :boolean, :desc => "Don't pretty print errors, raise with a stack trace."
  # class_option :'skip-dependancies', :type => :boolean, :desc => "Don't validate and run dependencies."

  commands_from(File.join(File.dirname(__FILE__), 'cli'))

  desc 'Update infrastructure nodes and/or groups.'
  command :update do |cupdate|

  end


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
    true
  end

end
