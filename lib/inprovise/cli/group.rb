# CLI Group commands for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Cli

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

end
