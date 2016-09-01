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
    destination = @context.remote(destination) if String === destination
    if destination.is_local?
      download(destination)
    else
      duplicate(destination)
    end
  end

  def move_to(destination)
    destination = @context.remote(destination) if String === destination
    if destination.is_local?
      download(destination)
    else
      @context.move(path, destination.path)
    end
    destination
  end

  def copy_from(source)
    source = @context.remote(source) if String === source
    source.copy_to(self)
  end

  def duplicate(destination)
    destination = @context.remote(destination) if String === destination
    @context.copy(path, destination.path)
    destination
  end

  def download(destination)
    destination = @context.local(destination) if String === destination
    if destination.is_local?
      @context.download(path, destination.path)
    else
      @context.copy(path, destination.path)
    end
    destination
  end

  def upload(source)
    source = @context.local(source) if String === source
    if source.is_local?
      @context.upload(source.path, path)
    else
      @context.copy(source.path, path)
    end
    self
  end

  def delete!
    @context.remove(path) if exists?
    invalidate!
    self
  end

  def set_permissions(mask)
    @context.set_permissions(path, mask)
    invalidate!
    self
  end

  def permissions
    @permissions ||= @context.node.permissions(path)
  end

  def set_owner(user, group=nil)
    user ||= owner[:user]
    @context.set_owner(path, user, group)
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
