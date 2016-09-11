# Config tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::Config do

  it 'creates an empty instance' do
    @config = Inprovise::Config.new
    @config.empty?.must_equal true
  end

  it 'creates an instance from Hash' do
    @config = Inprovise::Config.new({ :key => 'value'})
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    @config[:key].must_equal 'value'
  end

  it 'creates an instance from Config' do
    tmp = Inprovise::Config.new({ :key => 'value'})
    @config = Inprovise::Config.new(tmp)
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    @config[:key].must_equal 'value'
  end

  it 'copies initialization values' do
    tmp = Inprovise::Config.new({ :key => %w{value1 value2}, :key2 => { :another => 999} })
    @config = Inprovise::Config.new(tmp)
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    tmp[:key] << 'value3'
    tmp[:key].size.must_equal 3
    @config[:key].size.must_equal 2
    tmp[:key].first << 'X'
    # but not recursively (except for hashes/config)
    tmp[:key].first.must_equal 'value1X'
    @config[:key].first.must_equal 'value1X'
    tmp[:key2][:another] = 100
    tmp[:key2][:another].must_equal 100
    @config[:key2][:another].must_equal 999
  end

  it 'merges configurations' do
    tmp = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config = Inprovise::Config.new({ :key => 'value'})
    @config.merge!(tmp)
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    @config[:key].must_equal 'value1'
    @config[:key2].must_equal 'value2'
  end

  it 'copies configurations' do
    tmp = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config = Inprovise::Config.new({ :key => 'value'})
    @config.copy!(tmp)
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    tmp[:key].tr!('1', '')
    tmp[:key].must_equal 'value'
    @config[:key].must_equal 'value1'
    @config[:key2].must_equal 'value2'
  end

  it 'updates configurations' do
    tmp = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config = Inprovise::Config.new({ :key => 'value'})
    @config.update!(tmp)
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    tmp[:key].must_equal 'value1'
    @config[:key].must_equal 'value'
    @config[:key2].must_equal 'value2'
  end

  it 'iterates content' do
    @config = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config.each do |k,v|
      [:key, :key2].must_include k
      v.must_equal 'value1' if k == :key
      v.must_equal 'value2' if k == :key2
    end
  end

  it 'returns Hash' do
    @config = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config.to_h.must_be_kind_of Hash
    @config.to_h[:key].must_equal 'value1'
  end

  it 'duplicates Config' do
    tmp = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config = tmp.dup
    @config.empty?.must_equal false
    @config.has_key?(:key).must_equal true
    tmp[:key].tr!('1', '')
    tmp[:key].must_equal 'value'
    @config[:key].must_equal 'value1'
    @config[:key2].must_equal 'value2'
  end

  it 'supports method_missing access to members' do
    @config = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config.key.must_equal 'value1'
    @config[:key2].must_equal 'value2'
    @config.key2 = 'value3'
    @config.key2.must_equal 'value3'
    @config[:key2].must_equal 'value3'
  end

  it 'converts hashes to Config' do
    @config = Inprovise::Config.new({ :key => 'value1', :key2 => 'value2'})
    @config[:key3] = {}
    @config[:key3].must_be_kind_of Inprovise::Config
    @config.key4 = {}
    @config.key4.must_be_kind_of Inprovise::Config
    @config.key5 ||= {}
    @config.key5.must_be_kind_of Inprovise::Config
  end
end
