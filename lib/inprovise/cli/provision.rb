# CLI provisioning commands for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Cli

  def self.setup_provisioning_cmd(cmd, &block)
    cmd.desc 'Path to a provisioning scheme to load'
    cmd.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    cmd.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the script execution'
    cmd.action(&block)
  end

  desc 'Apply the given script/package to the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT TARGET[ TARGET[...]]'
  command :apply do |capply|

    Inprovise::Cli.setup_provisioning_cmd(capply) do |_global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:apply, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Revert the given script/package on the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT NAME[ NAME[...]]'
  command :revert do |crevert|

    Inprovise::Cli.setup_provisioning_cmd(crevert) do |_global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:revert, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Validate the given script/package on the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT NAME[ NAME[...]]'
  command :validate do |cvalid|

    Inprovise::Cli.setup_provisioning_cmd(cvalid) do |_global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:validate, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Trigger a specific action on the specified infrastructure nodes and/or groups.'
  arg_name 'ACTION NAME[ NAME[...]]'
  command :trigger do |ctrigger|

    Inprovise::Cli.setup_provisioning_cmd(ctrigger) do |_global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:trigger, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'List the available scripts. By default lists only described scripts.'
  skips_post
  command :list do |clist|

    clist.desc 'Path to a provisioning scheme to load'
    clist.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    clist.switch [:a, :all], negatable: false, :desc => 'List all scripts (with or without description)'

    clist.action do |_global, options, _args|
      Inprovise::Controller.list_scripts(options)
    end
  end

end
