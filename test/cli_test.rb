# CLI tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'cli_test_helper'

describe Inprovise::Cli do
  describe "'node' commands" do
    after :each do
      reset_infrastructure!
    end

    it 'adds a node to the infrastructure' do
      Inprovise::Cli.run(%w{node add -a host.address --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      tgt.host.must_equal 'host.address'
    end

    it 'adds a node with implicit host address' do
      Inprovise::Cli.run(%w{node add --no-sniff my.host.addr})
      tgt = Inprovise::Infrastructure.find('my.host.addr')
      tgt.name.must_equal 'my.host.addr'
      tgt.host.must_equal tgt.name
    end

    it 'adds a node with custom config' do
      Inprovise::Cli.run(%w{node add -a host.address -c config1=value1 -c config2=123 -c config3=Time.now --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.config[:config1].must_equal 'value1'
      tgt.config[:config2].must_equal 123
      tgt.config[:config3].must_be_instance_of Time
    end

    it 'removes a node from the infrastructure' do
      Inprovise::Cli.run(%w{node add -a host.address --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      Inprovise::Cli.run(%w{node remove MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_nil
    end

    it 'updates a node from the infrastructure' do
      Inprovise::Cli.run(%w{node add -a host.address --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      tgt.config[:config1].must_be_nil
      Inprovise::Cli.run(%w{node update -c config1=value1 --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      tgt.config[:config1].must_equal 'value1'
    end
  end

  describe "'group' commands" do
    after :each do
      reset_infrastructure!
    end

    it 'adds a group to the infrastructure' do
      Inprovise::Cli.run(%w{group add MyGroup})
      tgt = Inprovise::Infrastructure.find('MyGroup')
      tgt.must_be_instance_of Inprovise::Infrastructure::Group
      tgt.name.must_equal 'MyGroup'
    end

    it 'removes a group from the infrastructure' do
      Inprovise::Cli.run(%w{group add MyGroup})
      tgt = Inprovise::Infrastructure.find('MyGroup')
      tgt.must_be_instance_of Inprovise::Infrastructure::Group
      tgt.name.must_equal 'MyGroup'
      Inprovise::Cli.run(%w{group remove MyGroup})
      tgt = Inprovise::Infrastructure.find('MyGroup')
      tgt.must_be_nil
    end

    it 'adds a group with custom config' do
      Inprovise::Cli.run(%w{group add -c config1=value1 -c config2=123 -c config3=Time.now MyGroup})
      tgt = Inprovise::Infrastructure.find('MyGroup')
      tgt.config[:config1].must_equal 'value1'
      tgt.config[:config2].must_equal 123
      tgt.config[:config3].must_be_instance_of Time
    end

    it 'adds a node to a group' do
      Inprovise::Cli.run(%w{group add MyGroup})
      grp = Inprovise::Infrastructure.find('MyGroup')
      grp.must_be_instance_of Inprovise::Infrastructure::Group
      grp.name.must_equal 'MyGroup'
      Inprovise::Cli.run(%w{node add -g MyGroup --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      grp.targets.must_equal [tgt]
    end

    it 'adds a group including a node' do
      Inprovise::Cli.run(%w{node add --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      Inprovise::Cli.run(%w{group add -t MyHost MyGroup})
      grp = Inprovise::Infrastructure.find('MyGroup')
      grp.must_be_instance_of Inprovise::Infrastructure::Group
      grp.name.must_equal 'MyGroup'
      grp.targets.must_equal [tgt]
    end

    it 'updates a group with a node' do
      Inprovise::Cli.run(%w{node add --no-sniff MyHost})
      tgt = Inprovise::Infrastructure.find('MyHost')
      tgt.must_be_instance_of Inprovise::Infrastructure::Node
      tgt.name.must_equal 'MyHost'
      Inprovise::Cli.run(%w{group add MyGroup})
      grp = Inprovise::Infrastructure.find('MyGroup')
      grp.must_be_instance_of Inprovise::Infrastructure::Group
      grp.name.must_equal 'MyGroup'
      Inprovise::Cli.run(%w{group update -t MyHost MyGroup})
      grp.targets.must_equal [tgt]
    end

    it 'updates a group with custom config' do
      Inprovise::Cli.run(%w{group add MyGroup})
      tgt = Inprovise::Infrastructure.find('MyGroup')
      tgt.must_be_instance_of Inprovise::Infrastructure::Group
      tgt.name.must_equal 'MyGroup'
      tgt.config[:config1].must_be_nil
      Inprovise::Cli.run(%w{group update -c config1='value1' MyGroup})
      tgt.config[:config1].must_equal 'value1'
    end
  end

  describe "'apply' command" do

    it 'invokes the Inprovise::Controller#run appropriately' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :apply
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{apply script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom scheme' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :apply
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{apply -s myscheme.rb script node})
        Inprovise.loaded?('myscheme.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom config' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :apply
        opts[:config1] = 'value1'
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{apply -c config1=value1 script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

  end

  describe "'revert' command" do

    it 'invokes the Inprovise::Controller#run appropriately' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd, tgt, opts,*args|
        cmd.must_equal :revert
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{revert script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom scheme' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :revert
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{revert -s myscheme.rb script node})
        Inprovise.loaded?('myscheme.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom config' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :revert
        opts[:config1] = 'value1'
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{revert -c config1=value1 script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

  end

  describe "'validate' command" do

    it 'invokes the Inprovise::Controller#run appropriately' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :validate
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{validate script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom scheme' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :validate
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{validate -s myscheme.rb script node})
        Inprovise.loaded?('myscheme.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom config' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :validate
        opts[:config1] = 'value1'
        tgt.must_equal 'script'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{validate -c config1=value1 script node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

  end

  describe "'trigger' command" do

    it 'invokes the Inprovise::Controller#run appropriately' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :trigger
        tgt.must_equal 'script:action'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{trigger script:action node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom scheme' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :trigger
        tgt.must_equal 'script:action'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{trigger -s myscheme.rb script:action node})
        Inprovise.loaded?('myscheme.rb').must_equal true
      end
    end

    it 'invokes the Inprovise::Controller#run with custom config' do
      ctl = Inprovise::Controller.new
      ctl.expects(:run_provisioning_command).with() do |cmd,tgt,opts,*args|
        cmd.must_equal :trigger
        opts[:config1] = 'value1'
        tgt.must_equal 'script:action'
        args.shift.must_equal 'node'
      end
      Inprovise::Controller.stub(:new, ctl) do
        Inprovise::Cli.run(%w{trigger -c config1=value1 script:action node})
        Inprovise.loaded?('inprovise.rb').must_equal true
      end
    end

  end
end
