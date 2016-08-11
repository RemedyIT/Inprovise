# Script base class for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Script
  attr_reader :name, :dependencies, :actions, :children, :user

  class DSL
    def initialize(script)
      @script = script
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
    @user = nil
    @dependencies = []
    @children = []
    @actions = {}
    @commands = {}
    @remove = nil
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
      @commands[name.to_sym]
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
    Inprovise.log.local("Adding provisiong script #{name}") if Inprovise.verbosity > 1
    Inprovise.add_script(Inprovise::Script.new(name)) do |script|
      Inprovise::Script::DSL.new(script).instance_eval(&definition)
    end
  end
end
