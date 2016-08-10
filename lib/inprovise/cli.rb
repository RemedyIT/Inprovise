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

  desc 'Manage infrastructure nodes'
  command :node do |cnod|

    cnod.desc 'Add an infrastructure node'
    cnod.arg_name 'NODE'
    cnod.command :add do |cnod_add|

      cnod_add.flag [:a, :address], :arg_name => 'ADDRESS', :desc => 'Set the node address (hostname or IP). If not set node name is used as hostname.'
      cnod_add.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the node.'
      cnod_add.flag [:g, :group], :arg_name => 'GROUP', :multiple => true, :desc => 'Existing infrastructure group to add new node to.'
      cnod_add.flag [:k, :'public-key'], :arg_name => 'KEY', :desc => 'Public key to install for future authentication.'

      cnod_add.action do |global,options,args|
        raise ArgumentError, 'Missing or too many arguments!' unless args.size == 1
        ctl = Inprovise::Controller.new(global)
        ctl.run(:add, options, :node, *args)
      end

    end

    cnod.desc 'Remove (an) infrastructure node(s)'
    cnod.arg_name 'NODE[ NODE [...]]'
    cnod.command :remove do |cnod_del|

      cnod_del.action do |global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        ctl = Inprovise::Controller.new(global)
        ctl.run(:remove, options, :node, *args)
      end

    end

    cnod.default_desc 'List infrastructure nodes'
    cnod.action do |global_options,options,args|
      $stderr.puts "\tINFRASTRUCTURE NODES"
      $stderr.puts "\t===================="
      $stdout.puts *Inprovise::Infrastructure.list(Inprovise::Infrastructure::Node).collect {|n| "\t#{n.to_s}" }
    end

  end

  desc 'Manage infrastructure groups'
  command :group do |cgrp|

    cgrp.desc 'Add an infrastructure group'
    cgrp.arg_name 'GROUP'
    cgrp.command :add do |cgrp_add|

      cgrp_add.flag [:t, :target], :arg_name => 'NAME', :multiple => true, :desc => 'Add a known target (node or group) to this new group.'
      cgrp_add.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the group.'

      cgrp_add.action do |global,options,args|
        raise ArgumentError, 'Missing or too many arguments!' unless args.size == 1
        ctl = Inprovise::Controller.new(global)
        ctl.run(:add, options, :group, *args)
      end

    end

    cgrp.desc 'Remove (an) infrastructure group(s)'
    cgrp.arg_name 'GROUP[ GROUP [...]]'
    cgrp.command :remove do |cgrp_del|

      cgrp_del.action do |global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        ctl = Inprovise::Controller.new(global)
        ctl.run(:remove, options, :group, *args)
      end

    end

    cgrp.default_desc 'List infrastructure groups'
    cgrp.action do |global_options,options,args|
      $stderr.puts "\tINFRASTRUCTURE GROUPS"
      $stderr.puts "\t====================="
      $stdout.puts *Inprovise::Infrastructure.list(Inprovise::Infrastructure::Group).collect {|n| "\t#{n.to_s}" }
    end

  end

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
