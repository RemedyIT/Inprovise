# Script base class for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Script
  attr_reader :name, :dependencies, :actions, :children, :user, :configuration

  class DSL
    def initialize(script)
      @script = script
    end

    def description(desc)
      @script.description(desc)
    end
    alias :describe :description

    def configure(cfg=nil, &block)
      @script.configure(cfg, &block)
    end
    alias :configuration :configure

    def depends_on(*scr_names)
      @script.depends_on(*scr_names)
    end

    def triggers(*scr_names)
      @script.triggers(*scr_names)
    end

    def validate(&definition)
      @script.validate(&definition)
    end

    def apply(&definition)
      @script.apply(&definition)
    end

    def revert(&definition)
      @script.revert(&definition)
    end

    def as(user)
      @script.as(user)
    end

    def action(name, &definition)
      @script.action(name, &definition)
    end
  end

  def initialize(name)
    @name = name
    @description = nil
    @configuration = nil
    @user = nil
    @dependencies = []
    @children = []
    @actions = {}
    @commands = {}
    @remove = nil
  end

  def description(desc=nil)
    @description = desc if desc
    @description
  end

  def describe
    return [self.name] unless self.description
    nm = [self.name]
    self.description.split("\n").collect {|ld| "#{"%-25s" % nm.shift.to_s}\t#{ld.strip}"}
  end

  def configure(cfg=nil, &definition)
    @configuration = Inprovise::Config.new.merge!(cfg) if cfg
    command(:configure, &definition)
    @configuration
  end

  def update_configuration(context)
    if @configuration
      context.config[self.name.to_sym] ||= Inprovise::Config.new
      context.config[self.name.to_sym].update!(@configuration)
    end
  end

  def depends_on(*scr_names)
    scr_names.each do |scr_name|
      @dependencies << scr_name
    end
  end

  def triggers(*scr_names)
    scr_names.each do |scr_name|
      @children << scr_name
    end
  end

  def validate(&definition)
    command(:validate, &definition)
  end

  def apply(&definition)
    command(:apply, &definition)
  end

  def revert(&definition)
    command(:revert, &definition)
  end

  def as(user)
    @user = user
  end

  def action(name, &definition)
    @actions[name] = definition
  end

  def command(name, &definition)
    if block_given?
      (@commands[name.to_sym] ||= []) << definition
    else
      @commands[name.to_sym] ||= []
    end
  end

  def provides_command?(name)
    @commands.has_key?(name.to_sym)
  end

  def to_s
    self.name
  end
end

Inprovise::DSL.dsl_define do
  def script(name, &definition)
    Inprovise.log.local("Adding provisioning script #{name}") if Inprovise.verbosity > 1
    Inprovise.add_script(Inprovise::Script.new(name)) do |script|
      Inprovise::Script::DSL.new(script).instance_eval(&definition)
    end
  end
end
