# CLI Group commands for Inprovise
#
# Author::    Martin Corino
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
        Inprovise::Controller.run(:add, options, :group, *args)
        Inprovise::Controller.wait!
      end

    end

    cgrp.desc 'Remove (an) infrastructure group(s)'
    cgrp.arg_name 'GROUP[ GROUP [...]]'
    cgrp.command :remove do |cgrp_del|

      cgrp_del.action do |global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        Inprovise::Controller.run(:remove, options, :group, *args)
        Inprovise::Controller.wait!
      end

    end

    cgrp.desc 'Update configuration for the given groups.'
    cgrp.arg_name 'GROUP[ GROUP [...]]'
    cgrp.command :update do |cgrp_update|

      cgrp_update.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the group(s)'
      cgrp_update.switch [:r, :reset], negatable: false, :desc => 'Reset configuration before update (default is to merge updates)'
      cgrp_update.flag [:t, :target], :arg_name => 'NAME', :multiple => true, :desc => 'Add a known target (node or group) to the group(s)'

      cgrp_update.action do |global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        Inprovise::Controller.run(:update, options, :group, *args)
        Inprovise::Controller.wait!
      end
    end

    cgrp.desc 'List infrastructure groups (all or specified group(s))'
    cgrp.arg_name '[GROUP[ GROUP [...]]]'
    cgrp.command :list do |cgrp_list|
      cgrp_list.switch [:d, :details], negatable: false, :desc => 'Show group details'

      cgrp_list.action do |global_options,options,args|
        $stdout.puts "\tINFRASTRUCTURE GROUPS"
        $stdout.puts "\t====================="
        if args.empty?
          Inprovise::Infrastructure.list(Inprovise::Infrastructure::Group).each do |g|
            Inprovise::Cli.show_target(g, options[:details])
          end
        else
          args.each do |a|
            tgt = Inprovise::Infrastructure.find(a)
            case tgt
              when Inprovise::Infrastructure::Node
                $stdout.puts "ERROR: #{a} is not a group".red
              when Inprovise::Infrastructure::Group
                Inprovise::Cli.show_target(tgt, options[:details])
              else
                $stdout.puts "ERROR: #{a} is unknown".red
            end
          end
        end
        $stdout.puts
      end
    end

    cgrp.default_command :list

  end

end
