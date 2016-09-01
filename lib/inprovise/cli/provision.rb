# CLI provisioning commands for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Cli

  desc 'Apply the given script/package to the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT TARGET[ TARGET[...]]'
  command :apply do |capply|

    capply.desc 'Path to a provisioning scheme to load'
    capply.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    capply.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the script execution'

    capply.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:apply, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Revert the given script/package on the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT NAME[ NAME[...]]'
  command :revert do |crevert|

    crevert.desc 'Path to a provisioning scheme to load'
    crevert.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    crevert.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the script execution'

    crevert.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:revert, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Validate the given script/package on the specified infrastructure nodes and/or groups.'
  arg_name 'SCRIPT NAME[ NAME[...]]'
  command :validate do |cvalid|

    cvalid.desc 'Path to a provisioning scheme to load'
    cvalid.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    cvalid.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the script execution'

    cvalid.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:validate, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'Trigger a specific action on the specified infrastructure nodes and/or groups.'
  arg_name 'ACTION NAME[ NAME[...]]'
  command :trigger do |ctrigger|

    ctrigger.desc 'Path to a provisioning scheme to load'
    ctrigger.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    ctrigger.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the script execution'

    ctrigger.action do |global, options, args|
      raise ArgumentError, 'Missing arguments!' if args.empty?
      raise ArgumentError, 'Missing targets!' if args.size < 2
      Inprovise::Controller.run(:trigger, options, *args)
      Inprovise::Controller.wait!
    end
  end

  desc 'List the available scripts. By default lists only described scripts.'
  command :list do |clist|

    clist.desc 'Path to a provisioning scheme to load'
    clist.flag [:s,:scheme], :arg_name => 'FILE', :multiple => true, :default_value => Inprovise.default_scheme
    clist.switch [:a, :all], negatable: false, :desc => 'List all scripts (with or without description)'

    clist.action do |global, options, args|
      Inprovise::Controller.list_scripts(options)
    end
  end

end
