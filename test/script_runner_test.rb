# ScriptRunner  tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::ScriptRunner do
  before :each do
    @node = Inprovise::Infrastructure::Node.new('myNode', {channel: 'test', helper: 'test'})
    Inprovise::DSL.module_eval do

      script 'first' do
        apply do
        end

        revert do
        end
      end

      script 'second' do
        depends_on 'first'
      end

      script 'third' do
        depends_on 'second'
      end

      script 'four' do
        triggers 'third'
      end

      script 'validate' do
        apply do
        end

        revert do
        end

        validate do
        end
      end

      script 'invalid' do
        validate do
          false
        end
      end

    end
  end

  after :each do
    reset_script_index!
    reset_infrastructure!
  end

  describe 'dependencies' do
    it 'resolves a script without dependencies' do
      @runner = Inprovise::ScriptRunner.new(@node, 'first')
      @runner.scripts.collect {|s| s.name }.must_equal %w(first)
    end

    it 'resolves a script with dependencies' do
      @runner = Inprovise::ScriptRunner.new(@node, 'second')
      @runner.scripts.collect {|s| s.name }.must_equal %w(first second)
    end

    it 'resolves a triggering script' do
      @runner = Inprovise::ScriptRunner.new(@node, 'four')
      @runner.scripts.collect {|s| s.name }.must_equal %w(four first second third)
    end
  end

  describe 'execute' do

    describe 'apply' do
      it 'applies a script without dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'first')
        @runner.expects(:execute_apply).once
               .with() { |script, context| script.name.must_equal('first') && Inprovise::ExecutionContext === context }
        @runner.execute(:apply)
      end

      it 'applies a script with dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'second')
        expected_script_order = %w(first second)
        @runner.expects(:execute_apply).twice
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:apply)
      end

      it 'applies a triggering script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'four')
        expected_script_order = %w(four first second third)
        @runner.expects(:execute_apply).times(4)
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:apply)
      end

      it 'validates before and after applying a script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'validate')
        @runner.expects(:exec).twice
               .with() { |script, cmd, context| script.name.must_equal('validate') && Inprovise::ExecutionContext === context && (cmd == :configure || cmd == :apply) }
        @runner.expects(:is_valid?).twice
               .with() { |script, context| script.name.must_equal('validate') && Inprovise::ExecutionContext === context }
               .returns(false, true)
        @runner.execute(:apply)
      end
    end

    describe 'revert' do
      it 'reverts a script without dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'first')
        @runner.expects(:execute_revert).once
               .with() { |script, context| script.name.must_equal('first') && Inprovise::ExecutionContext === context }
        @runner.execute(:revert)
      end

      it 'reverts a script with dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'second')
        expected_script_order = %w(first second).reverse
        @runner.expects(:execute_revert).twice
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:revert)
      end

      it 'reverts a triggering script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'four')
        expected_script_order = %w(four first second third).reverse
        @runner.expects(:execute_revert).times(4)
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:revert)
      end

      it 'validates before reverting a script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'validate')
        @runner.expects(:exec).twice
               .with() { |script, cmd, context| script.name.must_equal('validate') && Inprovise::ExecutionContext === context && (cmd == :configure || cmd == :revert) }
        @runner.expects(:is_valid?).once
               .with() { |script, context| script.name.must_equal('validate') && Inprovise::ExecutionContext === context }
               .returns(true)
        @runner.execute(:revert)
      end
    end

    describe 'validate' do
      it 'validates a script without dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'first')
        @runner.expects(:execute_validate).once
               .with() { |script, context| script.name.must_equal('first') && Inprovise::ExecutionContext === context }
        @runner.execute(:validate)
      end

      it 'validates a script with dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'second')
        expected_script_order = %w(first second)
        @runner.expects(:execute_validate).twice
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:validate)
      end

      it 'validates a triggering script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'four')
        expected_script_order = %w(four first second third)
        @runner.expects(:execute_validate).times(4)
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::ExecutionContext === context }
        @runner.execute(:validate)
      end

      it 'throws on validating an invalid script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'validate')
        @runner.expects(:is_valid?).once
               .with() { |script, context| script.name.must_equal('validate') && Inprovise::ExecutionContext === context }
               .returns(false)
        assert_raises Inprovise::ScriptRunner::ValidationFailureError do
          @runner.execute(:validate)
        end
      end
    end
  end

  describe 'demonstrate' do
    describe 'apply' do
      it 'demonstrates applying a script without dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'first')
        @runner.expects(:execute_apply).once
               .with() { |script, context| script.name.must_equal('first') && Inprovise::MockExecutionContext === context }
        @runner.demonstrate(:apply)
      end

      it 'demonstrates applying a script with dependencies' do
        @runner = Inprovise::ScriptRunner.new(@node, 'second')
        expected_script_order = %w(first second)
        @runner.expects(:execute_apply).twice
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::MockExecutionContext === context }
        @runner.demonstrate(:apply)
      end

      it 'demonstrates applying a triggering script' do
        @runner = Inprovise::ScriptRunner.new(@node, 'four')
        expected_script_order = %w(four first second third)
        @runner.expects(:execute_apply).times(4)
               .with() { |script, context| script.name.must_equal(expected_script_order.shift) && Inprovise::MockExecutionContext === context }
        @runner.demonstrate(:apply)
      end
    end
  end
end
