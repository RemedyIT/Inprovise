# Script base class for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'ostruct'

class Inprovise::Script
  attr_reader :name, :dependencies, :actions, :children, :user

  class DSL
    def initialize(script)
      @script = script
    end

    def description(desc)
      @script.description(desc)
    end

    def configuration(cfg)
      @script.configuration(cfg)
    end

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

  def configuration(cfg=nil)
    @configuration = cfg if cfg
    @configuration
  end

  def copy_config(cfg)
    case cfg
    when Hash, OpenStruct
      cfg.to_h.reduce(OpenStruct.new) { |os, (k,v)| os[k] = copy_config(v); os }
    when Array
      cfg.collect { |e| copy_config(e) }
    else
      cfg.dup rescue cfg
    end
  end
  private :copy_config

  def merge_config(runcfg, scrcfg)
    return scrcfg unless runcfg
    case runcfg
    when Hash, OpenStruct
      return runcfg unless scrcfg.respond_to?(:to_h)
      return scrcfg.to_h.reduce(runcfg) do |rc, (k,v)|
        case rc[k]
        when Hash,OpenStruct
          rc[k] = merge_config(rc[k], v)
        else
          rc[k] = v unless rc[k]
        end
        rc
      end
    else
      return runcfg
    end
  end
  private :merge_config

  def merge_configuration(config)
    return unless self.configuration
    script_cfg = copy_config(self.configuration)
    config[self.name.to_sym] = merge_config(config[self.name.to_sym], script_cfg)
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
