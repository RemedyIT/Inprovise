# Script base class for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Script
  attr_reader :name, :dependencies, :actions, :children, :user

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

  def remove(&definition)
    command(:remove, &definition)
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
    Inprovise.add_script(Inprovise::Script.new(name)) do |script|
      script.instance_eval(&definition)
    end
  end
end
