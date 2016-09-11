# Config class for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Config

  def initialize(other=nil)
    @table = {}
    copy!(other.to_h) if other
  end

  def _k_(key)
    Symbol === key ? key : key.to_s.to_sym
  end
  private :_k_

  def _v_(val)
    Hash === val ? self.class.new.merge!(val) : val
  end
  private :_v_

  def [](key)
    @table[_k_(key)]
  end

  def []=(key, val)
    @table[_k_(key)] = _v_(val)
  end

  def has_key?(key)
    @table.has_key?(_k_(key))
  end

  def empty?
    @table.empty?
  end

  def merge!(other)
    other.to_h.each do |k,v|
      case self[k]
      when self.class
        self[k].merge!(v)
      else
        self[k] = v
      end
    end
    self
  end

  def copy!(other)
    other.to_h.each do |k,v|
      case self[k]
      when self.class
        self[k].copy!(v)
      else
        self[k] = v.is_a?(Hash) ? v : (v.dup rescue v)
      end
    end
    self
  end

  def update!(other)
    other.to_h.each do |k,v|
      if self.has_key?(k)
        self[k].update!(v) if self.class === self[k]
      else
        self[k] = v.is_a?(Hash) ? v : (v.dup rescue v)
      end
    end
    self
  end

  def each(&block)
    @table.each { |k,v| block.call(k,v) }
  end

  def dup
    self.class.new(@table)
  end

  def to_h
    @table
  end

  def method_missing(method, *args)
    if /(.*)=$/ =~ method.to_s
      self[$1] = (args.size > 1 ? args : args.shift)
    else
      self[method]
    end
  end

end
