# CLI Node commands for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Cli

  desc 'Manage infrastructure nodes'
  command :node do |cnod|

    cnod.desc 'Add an infrastructure node'
    cnod.arg_name 'NODE'
    cnod.command :add do |cnod_add|

      cnod_add.flag [:a, :address], :arg_name => 'ADDRESS', :desc => 'Set the node address (hostname or IP). If not set node name is used as hostname.'
      cnod_add.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the node.'
      cnod_add.flag [:C, :credential], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a security credential setting for the node.'
      cnod_add.switch [:sniff], :default_value => true, :desc => 'Enable or disable running sniffers'
      cnod_add.flag [:g, :group], :arg_name => 'GROUP', :multiple => true, :desc => 'Existing infrastructure group to add new node to.'

      cnod_add.action do |_global,options,args|
        raise ArgumentError, 'Missing or too many arguments!' unless args.size == 1
        Inprovise::Controller.run(:add, options, :node, *args)
        Inprovise::Controller.wait!
      end

    end

    cnod.desc 'Remove (an) infrastructure node(s)'
    cnod.arg_name 'NODE[ NODE [...]]'
    cnod.command :remove do |cnod_del|

      cnod_del.action do |_global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        Inprovise::Controller.run(:remove, options, :node, *args)
        Inprovise::Controller.wait!
      end

    end

    cnod.desc 'Update node configuration for the given infrastructure node(s) or group(s).'
    cnod.arg_name 'NAME[ NAME [...]]'
    cnod.command :update do |cnod_update|

      cnod_update.flag [:c, :config], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a configuration setting for the node(s)'
      cnod_update.flag [:C, :credential], :arg_name => 'CFGKEY=CFGVAL', :multiple => true, :desc => 'Specify a security credential setting for the node.'
      cnod_update.switch [:r, :reset], negatable: false, :desc => 'Reset configuration before update (default is to merge updates)'
      cnod_update.switch [:sniff], :default_value => true, :desc => 'Enable or disable running sniffers'
      cnod_update.flag [:g, :group], :arg_name => 'GROUP', :multiple => true, :desc => 'Existing infrastructure group to add node(s) to.'

      cnod_update.action do |_global,options,args|
        raise ArgumentError, 'Missing argument!' if args.empty?
        Inprovise::Controller.run(:update, options, :node, *args)
        Inprovise::Controller.wait!
      end
    end

    cnod.desc 'List infrastructure nodes (all or for specified nodes/groups)'
    cnod.skips_post
    cnod.arg_name '[NAME[ NAME [...]]]'
    cnod.command :list do |cnod_list|
      cnod_list.switch [:d, :details], negatable: false, :desc => 'Show node details'

      cnod_list.action do |_global,options,args|
        $stdout.puts
        $stdout.puts '   INFRASTRUCTURE NODES'
        $stdout.puts '   ===================='
        if args.empty?
          Inprovise::Infrastructure.list(Inprovise::Infrastructure::Node).each do |n|
            Inprovise::Cli.show_target(n, options[:details])
          end
        else
          args.each do |a|
            tgt = Inprovise::Infrastructure.find(a)
            case tgt
              when Inprovise::Infrastructure::Node
                Inprovise::Cli.show_target(tgt, options[:details])
              when Inprovise::Infrastructure::Group
                $stdout.puts "   #{tgt}"
                $stdout.puts "   #{'-' * tgt.to_s.size}"
                tgt.targets.each {|n| Inprovise::Cli.show_target(n, options[:details]) }
                $stdout.puts "   #{'-' * tgt.to_s.size}"
              else
                $stdout.puts "ERROR: #{a} is unknown".red
            end
          end
        end
        $stdout.puts
      end
    end

    cnod.default_command :list

  end

end
