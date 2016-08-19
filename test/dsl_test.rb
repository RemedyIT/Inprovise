# DSL tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::DSL do
  describe "'script' command" do
    after :each do
      reset_script_index!
    end

    it 'adds a script to the index' do
      Inprovise::DSL.script('my-script') { nil }
      Inprovise::ScriptIndex.default.get('my-script').must_be_instance_of Inprovise::Script
    end

    it 'creates a new script based on the supplied name' do
      Inprovise::DSL.script('my-script') { nil }
      script = Inprovise::ScriptIndex.default.get('my-script')
      script.name.must_equal 'my-script'
    end

    it 'executes the given definition block in the script context' do
      Inprovise::DSL.script('my-script') { depends_on 'other-script' }
      script = Inprovise::ScriptIndex.default.get('my-script')
      script.dependencies.must_equal ['other-script']
    end
  end

  describe "'include' command" do
    after :each do
      reset_script_index!
    end

    it 'includes a provisioning scheme' do
      Inprovise::DSL.include(File.join(File.dirname(__FILE__), 'fixtures', 'include.rb'))
      script = Inprovise::ScriptIndex.default.get('included')
      script.name.must_equal 'included'
    end
  end
end
