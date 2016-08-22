# Command channel for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

module Inprovise::CmdChannel

  class << self

    def implementations
      @implementations ||= {}
    end

    def default_implementation
      @default ||= 'ssh'
    end

    def default_implementation=(impl)
      @default = impl
    end

    def define(impl, base=::Object, &definition)
      implklass = Class.new(base) do
        include Inprovise::CmdChannel
      end
      implklass.class_eval(&definition)
      implementations[impl.to_s] = implklass
      implklass
    end

    def open(node, impl)
      implementations[impl || default_implementation].new(node)
    end

  end

  def initialize(node)
    @node = node
  end

  # session management

  def close
    # noop
  end

  # command execution (MANDATORY)

  def run(command, forcelog=false)
    raise RuntimeError, 'UNIMPLEMENTED'
  end

  # MANDATORY file management routines

  def upload(from, to)
    raise RuntimeError, 'UNIMPLEMENTED'
  end

  def download(from, to)
    raise RuntimeError, 'UNIMPLEMENTED'
  end

  # OPTIONAL file management routines

  # not recursive
  # def mkdir(path)
  # end

  # def exists?(path)
  # end

  # def file?
  # end
  #
  # def directory?
  # end

  # def content
  # end

  # def delete(path)
  # end

  # def permissions(path)
  # end
  #
  # def set_permissions(path, perm)
  # end

  # def owner(path)
  # end
  #
  # def set_owner(path, user, group=nil)
  # end

end

require_relative './channel/ssh'
