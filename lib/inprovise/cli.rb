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

  desc 'Path to a provisioning scheme to load, if none specified loads ./inprovise.rb.'
  #default_value 'the default'
  arg_name 'FILE'
  flag [:s,:scheme]

  desc 'Increase verbosity, useful for debugging.'
  switch [:v, :verbose], {negatable: false}

  # class_option :throw,       :type => :boolean, :desc => "Don't pretty print errors, raise with a stack trace."
  # class_option :sequential,  :type => :boolean, :desc => "Don't run tasks in parrallel across nodes."
  # class_option :'skip-dependancies', :type => :boolean, :desc => "Don't validate and run dependencies."

  desc 'Manage the infrastructure'
  command :infra do |c|

    c.desc 'Manage infrastructure nodes'
    c.command :node do |cnod|

      cnod.desc 'Add an infrastructure node'
      cnod.command :add do |cnod_add|

      end

      cnod.desc 'Remove an infrastructure node'
      cnod.command :remove do |cnod_del|

      end

      c.default_desc 'List infrastructure nodes'
      c.action do |global_options,options,args|

      end

    end

    c.desc 'Manage infrastructure groups'
    c.command :group do |cgrp|

    end


  end

  pre do |global,command,options,args|
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
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
