# Script dependency Resolver for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Resolver
  attr_reader :scripts, :tree
  def initialize(script,index=nil)
    @script = script
    @index = index || Inprovise::ScriptIndex.default
    @last_seen = script
    @tree = [@script]
    @scripts = []
  end

  def resolve
    dependencies = @script.dependencies.reverse.map { |d| @index.get(d) }
    begin
      @tree += dependencies.map {|d| Inprovise::Resolver.new(d, @index).resolve.tree }
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
      add_script_children(script, arr)
      arr
    end
  end
  private :add_children

  def add_script_children(script, arr)
    script.children.each do |child_name|
      child = @index.get(child_name)
      unless arr.include?(child)
        arr << child
        add_script_children(child, arr)
      end
    end
  end
  private :add_script_children

  class CircularDependencyError < StandardError
    def initialize
      super('Circular dependecy detected')
    end
  end
end
