# Script Index for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::ScriptIndex
  attr_reader :index_name

  def initialize(index_name)
    @index_name = index_name
    @scripts = {}
  end

  def self.default
    @default ||= new('default')
  end

  def add(scr)
    @scripts[scr.name] = scr
  end

  def get(scr_name)
    scr = @scripts[scr_name]
    raise MissingScriptError.new(index_name, scr_name) if scr.nil?
    scr
  end

  def clear!
    @scripts = {}
  end

  class MissingScriptError < StandardError
    def initialize(index_name, script_name)
      @index_name = index_name
      @script_name = script_name
    end

    def message
      "script #{@script_name} could not be found in the index #{@index_name}"
    end
  end
end
