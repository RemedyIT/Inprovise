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

  # default init
  def initialize(channel)
    @channel = channel
  end

  # platform properties

  def admin_user
    nil
  end

  def env_reference(varname)
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

  def echo(arg)
    nil
  end

  def env(var)
    echo(env_reference(var))
  end

  def cat(path)
    nil
  end

  def hash(path)
    nil
  end

  def mkdir(path)
    nil
  end

  def exists?(path)
    false
  end

  def file?(path)
    false
  end

  def directory?(path)
    false
  end

  def copy(from, to)
    nil
  end

  def delete(path)
    nil
  end

  def permissions(path)
    0
  end

  def set_permissions(path, perm)
    nil
  end

  def owner(path)
    nil
  end

  def set_owner(path, user, group=nil)
    nil
  end

  def binary_exists?(bin)
    false
  end

end

require_relative './helper/linux'
require_relative './helper/cygwin'
require_relative './helper/windows'
