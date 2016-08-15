# Infrastructure tests for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::Infrastructure do
  after :each do
    reset_infrastructure!
  end

  describe '#new' do
    it 'creates a new node from parameters' do
      node = Inprovise::Infrastructure::Node.new('myNode')
      node.must_equal Inprovise::Infrastructure.find('myNode')
      node.host.must_equal 'myNode'
      node.user.must_equal 'root'
      node = Inprovise::Infrastructure::Node.new('myNode2', host: 'my.node2.addr', user: 'me')
      node.must_equal Inprovise::Infrastructure.find('myNode2')
      node.host.must_equal 'my.node2.addr'
      node.user.must_equal 'me'
    end

    it 'creates a new group from parameters' do
      grp = Inprovise::Infrastructure::Group.new('myGroup')
      grp.must_equal Inprovise::Infrastructure.find('myGroup')
      grp = Inprovise::Infrastructure::Group.new('myGroup2', myval: 'value')
      grp.must_equal Inprovise::Infrastructure.find('myGroup2')
      grp.config[:myval].must_equal 'value'
    end
  end

  describe '#get/#set' do

    before :each do
      Inprovise::Infrastructure::Node.new('myNode')
      Inprovise::Infrastructure::Node.new('myNode2', host: 'my.node2.addr', user: 'me')
      Inprovise::Infrastructure::Group.new('myGroup')
      Inprovise::Infrastructure::Group.new('myGroup2', myval: 'value')
    end

    it 'sets a property value' do
      node = Inprovise::Infrastructure.find('myNode')
      node.set(:setting1, 5)
      node.config[:setting1].must_equal 5
    end

    it 'gets a property value' do
      grp = Inprovise::Infrastructure.find('myGroup2')
      grp.get(:myval).must_equal 'value'
    end

  end

  describe '#add_to/#remove_from' do

    before :each do
      Inprovise::Infrastructure::Node.new('myNode')
      Inprovise::Infrastructure::Node.new('myNode2', host: 'my.node2.addr', user: 'me')
      Inprovise::Infrastructure::Group.new('myGroup')
      Inprovise::Infrastructure::Group.new('myGroup2', myval: 'value')
    end

    it 'adds a node to a group' do
      node = Inprovise::Infrastructure.find('myNode')
      node.add_to(Inprovise::Infrastructure.find('myGroup'))
      grp = Inprovise::Infrastructure.find('myGroup')
      assert grp.includes?('myNode')
      assert grp.includes?(node)
    end

    it 'adds a group to a group' do
      grp = Inprovise::Infrastructure.find('myGroup')
      grp.add_to(Inprovise::Infrastructure.find('myGroup2'))
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      assert grp2.includes?('myGroup')
      assert grp2.includes?(grp)
    end

    it 'allows overlapping inclusion' do
      node = Inprovise::Infrastructure.find('myNode')
      node.add_to(Inprovise::Infrastructure.find('myGroup'))
      grp = Inprovise::Infrastructure.find('myGroup')
      grp.add_to(Inprovise::Infrastructure.find('myGroup2'))
      node.add_to(Inprovise::Infrastructure.find('myGroup2'))
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      assert grp.includes?('myNode')
      assert grp.includes?(node)
      assert grp2.includes?('myNode')
      assert grp2.includes?(node)
    end

    it 'resolves inclusion recursively' do
      node = Inprovise::Infrastructure.find('myNode')
      grp = Inprovise::Infrastructure.find('myGroup')
      node.add_to(grp)
      grp.add_to(Inprovise::Infrastructure.find('myGroup2'))
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      assert grp2.includes?('myGroup')
      assert grp2.includes?(grp)
      assert grp2.includes?('myNode')
      assert grp2.includes?(node)
    end

    it 'removes targets non-recursively' do
      node = Inprovise::Infrastructure.find('myNode')
      grp = Inprovise::Infrastructure.find('myGroup')
      node.add_to(grp)
      grp.add_to(Inprovise::Infrastructure.find('myGroup2'))
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      assert grp2.includes?('myGroup')
      assert grp2.includes?(grp)
      assert grp2.includes?('myNode')
      assert grp2.includes?(node)
      node.remove_from(grp2)
      assert grp2.includes?(node)
      node.remove_from(grp)
      assert !grp2.includes?(node)
      assert grp2.includes?(grp)
      grp.remove_from(grp2)
      assert !grp2.includes?(grp)
    end

  end

  describe '#targets' do

    before :each do
      n = Inprovise::Infrastructure::Node.new('myNode')
      n2 = Inprovise::Infrastructure::Node.new('myNode2', host: 'my.node2.addr', user: 'me')
      g = Inprovise::Infrastructure::Group.new('myGroup')
      g2 = Inprovise::Infrastructure::Group.new('myGroup2', myval: 'value')
      n.add_to(g)
      n.add_to(g2)
      n2.add_to(g2)
      g.add_to(g2)
    end


    it 'resolves included (device) targets' do
      grp = Inprovise::Infrastructure.find('myGroup')
      grp.targets.size.must_equal 1
      grp.targets.must_include Inprovise::Infrastructure.find('myNode')
    end

    it 'resolves (device) targets recursively and uniquely' do
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      grp2.targets.size.must_equal 2
      grp2.targets.must_include Inprovise::Infrastructure.find('myNode')
      grp2.targets.must_include Inprovise::Infrastructure.find('myNode2')
    end

  end

  describe '#targets_with_config' do

    before :each do
      n = Inprovise::Infrastructure::Node.new('myNode', nodeval: 666)
      n2 = Inprovise::Infrastructure::Node.new('myNode2', host: 'my.node2.addr', user: 'me')
      g = Inprovise::Infrastructure::Group.new('myGroup', myval: 'value')
      g2 = Inprovise::Infrastructure::Group.new('myGroup2', myval2: 'value2')
      n.add_to(g)
      n.add_to(g2)
      n2.add_to(g2)
      g.add_to(g2)
    end

    it 'resolves (device) targets and config recursively and uniquely' do
      grp = Inprovise::Infrastructure.find('myGroup')
      grp.targets_with_config.size.must_equal 1
      grp.targets_with_config.must_include Inprovise::Infrastructure.find('myNode')
      grp.targets_with_config[Inprovise::Infrastructure.find('myNode')][:nodeval].must_equal 666
      grp.targets_with_config[Inprovise::Infrastructure.find('myNode')][:myval].must_equal 'value'
      grp.targets_with_config[Inprovise::Infrastructure.find('myNode')][:myval2].must_be_nil
      grp2 = Inprovise::Infrastructure.find('myGroup2')
      grp2.targets_with_config.size.must_equal 2
      grp2.targets_with_config.must_include Inprovise::Infrastructure.find('myNode')
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode')][:nodeval].must_equal 666
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode')][:myval].must_equal 'value'
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode')][:myval2].must_equal 'value2'
      grp2.targets_with_config.must_include Inprovise::Infrastructure.find('myNode2')
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode2')][:nodeval].must_be_nil
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode2')][:myval].must_be_nil
      grp2.targets_with_config[Inprovise::Infrastructure.find('myNode2')][:myval2].must_equal 'value2'
    end

  end
end
