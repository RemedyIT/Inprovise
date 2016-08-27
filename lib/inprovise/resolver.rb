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
    begin
      @script.dependencies.reverse.each do |d|
        @scripts.insert(0, *Inprovise::Resolver.new(@index.get(d), @index).resolve.scripts)
      end
      @script.children.each do |c|
        child = @index.get(c)
        @scripts.concat(Inprovise::Resolver.new(child, @index).resolve.scripts) unless @scripts.include?(child)
      end
    rescue SystemStackError
      raise CircularDependencyError.new
    end
    @scripts.uniq!
    self
  end

  class CircularDependencyError < StandardError
    def initialize
      super('Circular dependecy detected')
    end
  end
end
