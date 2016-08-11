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

  #desc 'Path to a provisioning scheme to load, if none specified loads ./inprovise.rb.'
  #default_value 'the default'
  #arg_name 'FILE'
  #flag [:s,:scheme]

  desc 'Increase verbosity, useful for debugging.'
  flag [:v, :verbose], :arg_name => 'LEVEL', :default_value => 0, :type => Integer

  desc 'Don\'t run tasks in parrallel across nodes.'
  switch [:sequential], {negatable: false}

  desc 'Don\'t validate and run dependencies.'
  switch [:'skip-dependencies'], {negatable: false}

  # class_option :throw,       :type => :boolean, :desc => "Don't pretty print errors, raise with a stack trace."

  commands_from(File.join(File.dirname(__FILE__), 'cli'))

  desc 'Apply the given script/package to the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT TARGET[ TARGET[...]]'
  command :apply do |capply|

    capply.desc 'Path to a provisioning scheme to load'
    capply.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => ENV['INPROVISE_SCHEME'] || 'inprovise.rb'

    capply.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      ctl = Inprovise::Controller.new(global)
      ctl.run(:apply, options, *args)
    end
  end

  desc 'Revert the given script/package on the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT NAME[ NAME[...]]'
  command :revert do |crevert|

    crevert.desc 'Path to a provisioning scheme to load'
    crevert.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => ENV['INPROVISE_SCHEME'] || 'inprovise.rb'

    crevert.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      ctl = Inprovise::Controller.new(global)
      ctl.run(:revert, options, *args)
    end
  end

  desc 'Trigger a specific action on the specified infrastructure nodes and/or groups.'
  arg_name 'ACTION NAME[ NAME[...]]'
  command :trigger do |ctrigger|

    ctrigger.desc 'Path to a provisioning scheme to load'
    ctrigger.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => ENV['INPROVISE_SCHEME'] || 'inprovise.rb'

    ctrigger.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      ctl = Inprovise::Controller.new(global)
      ctl.run(:trigger, options, *args)
    end
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
    if Inprovise.verbosity > 0
      $stderr.puts "#{exception}\n#{exception.backtrace.join("\n")}"
    end
    true
  end

end
