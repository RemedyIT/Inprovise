# Script index tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::ScriptIndex do
  before :each do
    @script = Inprovise::Script.new('my-script')
    @default = Inprovise::ScriptIndex.default
  end

  after :each do
    reset_script_index!
  end

  describe "default" do
    it "returns a script index singleton named default" do
      Inprovise::ScriptIndex.default.index_name.must_equal 'default'
    end

    it "allways returns the same script index" do
      Inprovise::ScriptIndex.default.must_equal Inprovise::ScriptIndex.default
    end
  end

  describe "add" do
    it "adds a script to the index" do
      @default.add(@script)
      @default.get(@script.name).must_equal @script
    end
  end

  describe 'get' do
    it "fetches a script by name" do
      @default.add(@script)
      @default.get(@script.name).must_equal @script
    end

    it "throws an execption if the script doesn't exist" do
      assert_raises(Inprovise::ScriptIndex::MissingScriptError) { @default.get(@script.name) }
    end
  end

  describe "clear!" do
    it "wipes the index clean of scripts" do
      @default.add(@script)
      @default.clear!
      assert_raises(Inprovise::ScriptIndex::MissingScriptError) { @default.get(@script.name) }
    end
  end
end
