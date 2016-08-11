# Trigger runner for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::TriggerRunner
  def initialize(node, action_ref_with_args)
    @node = node
    @action_ref, @args = *parse_action_ref(action_ref_with_args)
    @log = Inprovise::Logger.new(@node, @action_ref)
  end

  def execute(_, config=nil)
    Inprovise::ExecutionContext.new(@node, @log, config).trigger(@action_ref, *@args)
  end

  def demonstrate(_, config=nil)
    Inprovise::MockExecutionContext.new(@node, @log, config).trigger(@action_ref, *@args)
  end

  private

  def parse_action_ref(action_ref_with_args)
    matches = action_ref_with_args.match(/([\w\:]+?)(\[([\w\,]+?)\])/)
    return [action_ref_with_args,[]] unless matches
    action_ref = matches[1]
    args = matches[3].split(',').map(&:strip)
    [action_ref, args]
  end
end
