# Script dependency Resolver for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Resolver
  attr_reader :scripts, :tree
  def initialize(script)
    @script = script
    @last_seen = script
    @tree = [@script]
    @scripts = []
  end

  def resolve
    dependencies = @script.dependencies.reverse.map { |d| Inprovise::ScriptIndex.default.get(d) }
    begin
      @tree += dependencies.map {|d| Inprovise::Resolver.new(d).resolve.tree }
    rescue SystemStackError
      raise CircularDependencyError.new
    end
    @scripts = @tree.flatten
    @scripts.reverse!
    @scripts.uniq!
    add_children
    self
  end

  def add_children
    @scripts = @scripts.reduce([]) do |arr, script|
      arr << script
      script.children.each do |child_name|
        child = Inprovise::ScriptIndex.default.get(child_name)
        arr << child unless arr.include?(child)
      end
      arr
    end
  end

  class CircularDependencyError < StandardError
    def initialize
      super('Circular dependecy detected')
    end
  end
end
