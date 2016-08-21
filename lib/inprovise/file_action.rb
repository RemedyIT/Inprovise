# File action for scripts for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::FileAction

  module DSLExt
    def file(config, &action)
      Inprovise::FileAction.new(@script, config, &action).configure
    end
  end

  Inprovise::Script::DSL.send(:include, DSLExt)

  def initialize(script, config, &action)
    @script = script
    @config = config
    @after_apply = action
    raise ArgumentError, 'A file :source  or :template must be provided' unless @config[:source] or @config[:template]
    raise ArgumentError, 'A file :destination must be provided' unless @config[:destination]
  end

  def local_path(context)
    value_for context, @config[:source]
  end

  def template_path(context)
    tp = value_for context, @config[:template]
    File.exists?(tp) ? tp : Proc.new { tp }
  end

  def local_path_for_node(context)
    return local_path(context) if @config[:source]
    Inprovise::Template.new(template_path(context), context).render_to_tempfile
  end

  def remote_path(context)
    value_for context, @config[:destination]
  end

  def permissions(context)
    value_for context, @config[:permissions]
  end

  def user(context)
    value_for context, @config[:user]
  end

  def group(context)
    value_for context, @config[:group]
  end

  def create_dir(context)
    value_for context, (@config[:create_dir] || @config[:create_dirs])
  end

  def configure
    parent = add_script(@script) do
      apply do
      end
    end
    add_content_script(parent)
    add_permissions_script(parent) unless @config[:permissions].nil? and @config[:user].nil? and @config[:group].nil?
    add_after_apply_script(parent) if @after_apply
  end

  def run_after_apply(context)
    context.as(nil, &@after_apply) if @after_apply
  end

  def add_after_apply_script(parent)
    fa = self
    add_script(parent, '-after') do
      apply do
        fa.run_after_apply(self)
      end
    end
  end

  def add_content_script(parent)
    fa = self
    add_script(parent, '-content') do
      apply do
        if fa.create_dir(self)
          mk_dir = fa.create_dir(self) == true ? File.dirname(fa.remote_path(self)) : fa.create_dir(self)
          sudo("mkdir -p #{mk_dir}")
          sudo("chown #{fa.user(self)}:#{fa.group(self) || fa.user(self)} #{mk_dir}") if fa.user(self)
        end
        local_file = local(fa.local_path_for_node(self))
        tmp_path = "inprovise-tmp-#{local_file.hash}"
        local_file.copy_to(remote(tmp_path))
        sudo("mv #{tmp_path} #{fa.remote_path(self)}")
        #fa.run_after_apply(self)
      end

      revert do
        remote(fa.remote_path(self)).delete!
      end

      validate do
        local(fa.local_path_for_node(self)).matches?(remote(fa.remote_path(self)))
      end
    end
  end

  def add_permissions_script(parent)
    fa = self
    add_script(parent, '-permissions') do
      apply do
        remote(fa.remote_path(self)).set_owner(fa.user(self), fa.group(self)) unless fa.user(self).nil? and fa.group(self).nil?
        remote(fa.remote_path(self)).set_permissions(fa.permissions(self)) unless fa.permissions(self).nil?
        #fa.run_after_apply(self)
      end

      validate do
        r_file = remote(fa.remote_path(self))
        valid = r_file.permissions == fa.permissions(self)
        valid = valid && r_file.user == fa.user(self) if fa.user(self)
        valid = valid && r_file.group == fa.group(self) if fa.group(self)
        valid
      end
    end
  end

  def script_name(suffix)
    name = @config[:name]
    if name.nil? && !@config[:destination].is_a?(String)
      raise ArgumentError, 'You must provide a :name option unless :destination is a String'
    end
    name ||= @config[:destination]
    "file#{suffix}[#{name}]"
  end

  def add_script(parent, suffix=nil, &definition)
    script = Inprovise::DSL.script(script_name(suffix), &definition)
    parent.triggers(script.name)
    script
  end

  def value_for(context, option)
    return nil if option.nil?
    return context.instance_exec(&option) if option.respond_to?(:call)
    option
  end
end
