# Script dependency Resolver for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Resolver
  attr_reader :scripts
  def initialize(script,index=nil)
    @script = script
    @index = index || Inprovise::ScriptIndex.default
    @last_seen = script
    @scripts = [@script]
  end

  def resolve
    dependencies = @script.dependencies.reverse.map { |d| @index.get(d) }
    begin
      dependencies.each do |d|
        @scripts = Inprovise::Resolver.new(d, @index).resolve.scripts + @scripts
      end
    rescue SystemStackError
      raise CircularDependencyError.new
    end
    @scripts.uniq!
    add_children
    @scripts.uniq!
    self
  end

  def add_children
    @scripts = @scripts.reduce([]) do |list, script|
      list << script
      list.concat(resolve_children(script, list))
      list
    end
  end
  private :add_children

  def resolve_children(script, list)
    begin
      script.children.map do |cname|
        child = @index.get(cname)
        list.include?(child) ? [] : Inprovise::Resolver.new(child, @index).resolve.scripts
      end.flatten
    rescue SystemStackError
      raise CircularDependencyError.new
    end
  end
  private :resolve_children

  class CircularDependencyError < StandardError
    def initialize
      super('Circular dependecy detected')
    end
  end
end
