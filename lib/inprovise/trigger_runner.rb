# Trigger runner for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::TriggerRunner
  def initialize(node, action_ref_with_args, skip_dependencies=false)
    @node = node
    @action_ref, @args = *parse_action_ref(action_ref_with_args)
    @log = Inprovise::Logger.new(@node, @action_ref)
    @skip_dependencies = skip_dependencies
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

  def scripts(script)
    return [script] if @skip_dependencies
    resolver = Inprovise::Resolver.new(script, @index)
    resolver.resolve
    resolver.scripts
  end

  def setup_configuration(script, context)
    script_list = scripts(script)
    script_list.each { |scr| scr.update_configuration(context) }
    script_list.each do |scr|
      context.log.set_task(scr)
      context.log.command(:configure)
      context.script = scr
      scr.command(:configure).each {|cmd| context.exec_config(cmd) }
    end
  end

  def get_arg_value(v)
    begin
      Module.new { def self.eval(s); binding.eval(s); end }.eval(v)
    rescue Exception
      v
    end
  end

  def parse_action_ref(action_ref_with_args)
    matches = action_ref_with_args.match(/([\w\-\:]+?)(\[(.+?)\])/)
    return [action_ref_with_args,[]] unless matches
    action_ref = matches[1]
    args = matches[3].split(',').map { |arg| get_arg_value(arg.strip) }
    [action_ref, args]
  end
end
