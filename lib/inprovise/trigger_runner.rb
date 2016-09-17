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
    context = Inprovise::ExecutionContext.new(@node, @log, @index, config)
    scr, action = context.resolve_action_ref(@action_ref)
    setup_configuration(scr, context) if scr
    context.trigger(scr, action, *@args)
  end

  def demonstrate(_, config=nil)
    Inprovise.log.local("Demonstrating trigger #{@action_ref} for #{@node.to_s}")
    context = Inprovise::MockExecutionContext.new(@node, @log, @index, config)
    scr, action = context.resolve_action_ref(@action_ref)
    setup_configuration(scr, context) if scr
    context.trigger(scr, action, *@args)
  end

  private

  def setup_configuration(script, context)
    script.update_configuration(context)
    context.log.set_task(script)
    context.log.command(:configure)
    context.script = script
    script.command(:configure).each {|cmd| context.exec_config(cmd) }
  end

  def parse_action_ref(action_ref_with_args)
    matches = action_ref_with_args.match(/([\w\-\:]+?)(\[([\w\-\,]+?)\])/)
    return [action_ref_with_args,[]] unless matches
    action_ref = matches[1]
    args = matches[3].split(',').map(&:strip)
    [action_ref, args]
  end
end
