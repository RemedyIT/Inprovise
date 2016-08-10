# Infrastructure group for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'json'

class Inprovise::Infrastructure::Group < Inprovise::Infrastructure::Target

  def initialize(name, config={}, targets=[])
    @targets = targets.collect {|t| Inprovise::Infrastructure::Target === t ? t.name : t.to_s }
    super(name, config)
  end

  def add_target(tgt)
    @targets << (Inprovise::Infrastructure::Target === tgt ? tgt.name : tgt.to_s)
  end

  def remove_target(tgt)
    @targets.delete(Inprovise::Infrastructure::Target === tgt ? tgt.name : tgt.to_s)
  end

  def targets
    @targets.collect {|t| Inprovise::Infrastructure.find(t).targets }.flatten
  end

  def to_s
    "Group:#{name}"
  end

  def to_json(*a)
    {
      JSON.create_id  => self.class.name,
      :data => {
        :name => name,
        :config => config,
        :targets => @targets
      }
    }.to_json(*a)
  end

  def self.json_create(o)
    data = o[:data]
    new(data[:name], data[:config], data[:targets])
  end
end
