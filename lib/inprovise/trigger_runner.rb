# Trigger runner for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::TriggerRunner
  def initialize(node, action_ref_with_args)
    @node = node
    @action_ref, @args = *parse_action_ref(action_ref_with_args)
    @log = Inprovise::Logger.new(@node, @action_ref)
    @index = Inprovise::ScriptIndex.default
  end

  def set_index(index)
    @index = index
  end

  def execute(_, config=nil)
    Inprovise.log.local("Triggering #{@action_ref} for #{@node.to_s}")
    Inprovise::ExecutionContext.new(@node, @log, @index, config).trigger(@action_ref, *@args)
  end

  def demonstrate(_, config=nil)
    Inprovise::MockExecutionContext.new(@node, @log, @index, config).trigger(@action_ref, *@args)
  end

  private

  def parse_action_ref(action_ref_with_args)
    matches = action_ref_with_args.match(/([\w\-\:]+?)(\[([\w\-\,]+?)\])/)
    return [action_ref_with_args,[]] unless matches
    action_ref = matches[1]
    args = matches[3].split(',').map(&:strip)
    [action_ref, args]
  end
end
