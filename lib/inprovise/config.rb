# Config class for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Config

  def initialize(other=nil)
    @table = {}
    copy!(other) if other
  end

  def _v_(val)
    Hash === val ? self.class.new.merge!(val) : val
  end
  private :_v_

  def get(key)
    Symbol === key ? @table[key] : key.to_s.split('.').reduce(@table) { |t,k| t[k.to_sym] ||= self.class.new }
  end

  def set(key, val)
    if Symbol === key
      @table[key] = _v_(val)
    else
      vk = (path = key.to_s.split('.')).pop
      path.reduce(@table) { |t,k| t[k.to_sym] ||= self.class.new  }[vk.to_sym] = _v_(val)
    end
  end

  def [](key)
    get(key)
  end

  def []=(key, val)
    set(key, val)
  end

  def has_key?(key)
    if Symbol === key
      @table.has_key?(key)
    else
      !(key.to_s.split('.').reduce(@table) { |t,k| t && t.has_key?(k.to_sym) && self.class === t[k.to_sym] ? t[k.to_sym] : nil }).nil?
    end
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
    @table.reduce({}) do |hsh, (k,v)|
      hsh[k] = self.class === v ? v.to_h : v
      hsh
    end
  end

  def method_missing(method, *args)
    if /(.*)=$/ =~ method.to_s
      self[$1.to_sym] = (args.size > 1 ? args : args.shift)
    else
      self[method]
    end
  end

end
