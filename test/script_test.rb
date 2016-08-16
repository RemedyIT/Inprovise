# Script tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::Script do
  before :each do
    @script = Inprovise::Script.new('my-script')
  end

  describe "depends_on" do
    it "adds a dependency" do
      @script.dependencies.must_equal []
      @script.depends_on('other-script')
      @script.dependencies.must_equal ['other-script']
    end

    it "adds multiple dependancies at once" do
      @script.dependencies.must_equal []
      @script.depends_on('other-script', 'third-script')
      @script.dependencies.must_equal ['other-script', 'third-script']
    end
  end

  describe "action" do
    it "allows defining actions with a name and a block" do
      @script.action('my-action') { 'foo' }
      @script.actions['my-action'].call.must_equal 'foo'
    end
  end

  describe "commands" do
    it "can add an 'apply' command" do
      @script.apply { 'my-apply' }
      @script.command(:apply).first.call.must_equal 'my-apply'
    end

    it "can add an 'revert' command" do
      @script.revert { 'my-revert' }
      @script.command(:revert).first.call.must_equal 'my-revert'
    end

    it "can add an 'validate' command" do
      @script.validate { 'my-validate' }
      @script.command(:validate).first.call.must_equal 'my-validate'
    end

    it 'knows if a command is provided' do
      @script.provides_command?(:apply).must_equal false
      @script.apply { 'my-apply' }
      @script.provides_command?(:apply).must_equal true
    end
  end
end
