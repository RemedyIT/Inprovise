# Command helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

module Inprovise::CmdHelper

  class << self

    def implementations
      @implementations ||= {}
    end

    def default_implementation
      @default ||= 'linux'
    end

    def default_implementation=(impl)
      @default = impl
    end

    def define(impl, base=::Object, &definition)
      implklass = Class.new(base) do
        include Inprovise::CmdHelper
      end
      implklass.class_eval(&definition)
      implementations[impl.to_s] = implklass
      implklass
    end

    def get(node, impl)
      implementations[impl || default_implementation].new(node.channel)
    end

  end

  attr_reader :channel

  # default init
  def initialize(channel)
    @channel = channel
  end

  # platform properties

  def admin_user
    nil
  end

  def env_reference(_varname)
    nil
  end

  def cwd
    nil
  end

  # *must* return previous value
  def set_cwd(_path)
    nil
  end

  # generic command execution

  def run(cmd, forcelog=false)
    @channel.run(cmd,forcelog)
  end

  # return sudo helper
  def sudo
    nil
  end

  # file management

  def upload(from, to)
    @channel.upload(from, to)
  end

  def download(from, to)
    @channel.download(from, to)
  end

  # basic commands

  def echo(_arg)
    nil
  end

  def env(var)
    echo(env_reference(var))
  end

  def cat(_path)
    nil
  end

  def hash_for(_path)
    nil
  end

  def mkdir(_path)
    nil
  end

  def exists?(_path)
    false
  end

  def file?(_path)
    false
  end

  def directory?(_path)
    false
  end

  def copy(_from, _to)
    nil
  end

  def move(_from, _to)
    nil
  end

  def delete(_path)
    nil
  end

  def permissions(_path)
    0
  end

  def set_permissions(_path, _perm)
    nil
  end

  def owner(_path)
    nil
  end

  def set_owner(_path, _user, _group=nil)
    nil
  end

  def binary_exists?(_bin)
    false
  end

end

require_relative './helper/linux'
require_relative './helper/cygwin'
require_relative './helper/windows'
