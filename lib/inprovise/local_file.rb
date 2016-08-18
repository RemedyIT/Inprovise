# LocalFile support for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'digest/sha1'
require 'fileutils'
require 'etc'

class Inprovise::LocalFile
  attr_reader :path

  def initialize(path)
    @path = resolve(path)
  end

  def resolve(path)
    if path =~ /^\//
      path
    else
      File.join(Inprovise.root, path)
    end
  end

  def hash
    return nil unless exists?
    Digest::SHA1.file(path).hexdigest
  end

  def exists?
    File.exists?(@path)
  end

  def directory?
    File.directory?(path)
  end

  def file?
    File.file?(path)
  end

  def content
    return File.read(@path) if exists?
    nil
  end

  # deosnt check permissions or user. should it?
  def matches?(other)
    self.exists? && other.exists? && self.hash == other.hash
  end

  def copy_to(destination)
    if destination.is_local?
      duplicate(destination)
    else
      upload(destination)
    end
    destination
  end

  def copy_from(source)
    source.copy_to(self)
  end

  def duplicate(destination)
    FileUtils.cp(path, destination.path)
    destination
  end

  def upload(destination)
    destination = @context.remote(destination) if String === destination
    if destination.is_local?
      FileUtils.cp(path, destination.path)
    else
      destination.upload(self)
    end
    destination
  end

  def download(source)
    source = @context.remote(source) if String === source
    if source.is_local?
      FileUtils.cp(source.path, path)
    else
      source.download(self)
    end
    self
  end

  def delete!
    FileUtils.rm(path) if exists?
    self
  end

  def set_permissions(mask)
    FileUtils.chmod_R(mask, path)
    self
  end

  def permissions
     File.stat(path).mode & 0777
  end

  def set_owner(user, group=nil)
    FileUtils.chown_R(user, group, path)
    self
  end

  def user
    Etc.getpwuid(File.stat(path).uid).name
  end

  def group
    Etc.getgrgid(File.stat(path).gid).name
  end

  def is_local?
    true
  end
end
