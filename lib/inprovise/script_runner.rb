# Script runner for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::ScriptRunner
  COMMANDS = {apply: %w{Applying to}, revert: %w(Reverting on), validate: %w(Validating on)}

  def initialize(node, script, skip_dependencies=false)
    @node = node
    @script = script
    @index = Inprovise::ScriptIndex.default
    @perform = true
    @skip_dependencies = skip_dependencies
    @log = Inprovise::Logger.new(@node, script)
  end

  def set_index(index)
    @index = index
  end

  def script
    Inprovise::Script === @script ? @script : @index.get(@script)
  end

  def scripts
    return [script] if @skip_dependencies
    resolver = Inprovise::Resolver.new(script, @index)
    resolver.resolve
    resolver.scripts
  end

  def execute(command_name, config=nil)
    Inprovise.log.local("#{COMMANDS[command_name].first} #{script.name} #{COMMANDS[command_name].last} #{@node.to_s}")
    scrs = scripts
    scrs.reverse! if command_name.to_sym == :revert
    @log.say scrs.map(&:name).join(', ').yellow if Inprovise.verbosity > 0
    context = @perform ? Inprovise::ExecutionContext.new(@node, @log, @index, config) : Inprovise::MockExecutionContext.new(@node, @log, @index, config)
    context.config.command = command_name
    scrs.each { |script| script.merge_configuration(context.config) }
    scrs.each do |script|
      send(:"execute_#{command_name}", script, context)
    end
  end

  def demonstrate(command_name, config=nil)
    @perform = false
    execute(command_name, config)
    @perform = true
  end

  def execute_apply(script, context)
    return unless should_run?(script, :apply, context)
    exec(script, :apply, context)
    validate!(script, context)
  end

  def execute_revert(script, context)
    return unless should_run?(script, :revert, context)
    exec(script, :revert, context)
  end

  def execute_validate(script, context)
    validate!(script, context)
  end

  def should_run?(script, command_name, context)
    return false unless script.provides_command?(command_name)
    return true unless @perform
    return true unless command_name == :apply || command_name == :revert
    return true unless script.provides_command?(:validate)
    is_present = is_valid?(script, context)
    return !is_present if command_name == :apply
    is_present
  end

  def validate!(script, context)
    return true unless @perform
    return unless script.provides_command?(:validate)
    return if is_valid?(script, context)
    raise ValidationFailureError.new(@node, script)
  end

  def is_valid?(script, context)
    results = exec(script, :validate, context)
    rc = results.all?
    context.log.command("validate -> #{rc}") if Inprovise.verbosity > 0
    rc
  end

  def exec(script, command_name, context)
    cmds = script.command(command_name)
    context = context.for_user(script.user) if script.user
    context.log.set_task(script)
    context.log.command(command_name)
    context.script = script
    cmds.map {|cmd| context.exec(cmd) }
  end

  class ValidationFailureError < StandardError
    def initialize(node, script)
      @node = node
      @script = script
    end

    def message
      "Script #{@script.name} failed validation on #{@node.to_s}"
    end
  end
end
