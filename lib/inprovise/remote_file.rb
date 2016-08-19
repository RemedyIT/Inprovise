# RemoteFile support for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'digest/sha1'
require 'fileutils'

class Inprovise::RemoteFile
  attr_reader :path

  def initialize(context, path)
    @context = context
    @path = path
    @exists = nil
    @permissions = nil
    @owner = nil
  end

  def hash
    return nil unless exists?
    @hash ||= @context.node.hash_for(path)
  end

  def exists?
    return @exists unless @exists.nil?
    @exists = @context.node.exists?(path)
  end

  def directory?
    @context.node.directory?(path)
  end

  def file?
    @context.node.file?(path)
  end

  def content
    @context.node.cat(path)
  end

  # doesnt check permissions or user. should it?
  def matches?(other)
    self.exists? && other.exists? && self.hash == other.hash
  end

  def copy_to(destination)
    if destination.is_local?
      download(destination)
    else
      duplicate(destination)
    end
    destination
  end

  def copy_from(destination)
    destination.copy_to(self)
  end

  def duplicate(destination)
    @context.node.copy(path, destination.path)
    destination
  end

  def download(destination)
    if String === destination || destination.is_local?
      @context.download(path, String === destination ? destination : destination.path)
    else
      @context.node.copy(path, destination.path)
    end
    String === destination ? @context.local(destination) : destination
  end

  def upload(source)
    if String === source || source.is_local?
      @context.upload(String === source ? source : source.path, path)
    else
      @context.node.copy(source.path, path)
    end
    self
  end

  def delete!
    @context.node.delete(path) if exists?
    invalidate!
    self
  end

  def set_permissions(mask)
    @context.node.set_permissions(path, mask)
    invalidate!
    self
  end

  def permissions
    @permissions ||= @context.node.permissions(path)
  end

  def set_owner(user, group=nil)
    @context.node.set_owner(path, user, group)
    invalidate!
    self
  end

  def owner
    @owner ||= @context.node.owner(path)
  end

  def user
    owner[:user]
  end

  def group
    owner[:group]
  end

  def is_local?
    false
  end

  private

  def invalidate!
    @permissions = nil
    @owner = nil
  end
end
