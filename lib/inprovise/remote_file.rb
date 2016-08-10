# RemoteFile support for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
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
    @hash ||= @context.run("sha1sum #{path}")[0...40]
  end

  def exists?
    return @exists unless @exists.nil?
    result = @context.run(%[if [ -f #{path} ]; then echo "true"; else echo "false"; fi])
    @exists = result.strip == 'true'
  end

  def content
    @context.run("cat #{path}")
  end

  # deosnt check permissions or user. should it?
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
    @context.sudo("cp #{path} #{destination.path}")
    destination
  end

  def download(destination)
    @context.download(path, destination.path)
  end

  def upload(source)
    @context.upload(source.path, path)
  end

  def delete!
    @context.remove(path) if exists?
    invalidate!
    self
  end

  def set_permissions(mask)
    @context.sudo("chmod -R #{sprintf("%o",mask)} #{path}")
    invalidate!
    self
  end

  def permissions
    @permissions ||= @context.run("stat --format=%a #{path}").strip.to_i(8)
  end

  def set_owner(user, group=nil)
    @context.sudo("chown -R #{user}:#{group} #{path}")
    invalidate!
    self
  end

  def owner
    @owner ||= begin
      user, group = @context.run("stat --format=%U:%G #{path}").chomp.split(":")
      {:user => user, :group => group}
    end
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
