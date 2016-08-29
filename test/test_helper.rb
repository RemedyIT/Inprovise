# Test helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

gem 'minitest'
require 'minitest/autorun'
require 'mocha/setup'
require_relative '../lib/inprovise'

# force root file
ENV['INPROVISE_INFRA'] = File.join(File.dirname(__FILE__), 'fixtures', Inprovise::INFRA_FILE)

def reset_script_index!
  Inprovise::ScriptIndex.default.clear!
end

def reset_infrastructure!
  Inprovise::Infrastructure.reset
end

# patch Infrastructure#load and #save to do nothing
module Inprovise::Infrastructure
  class << self
    def load
      # noop
    end
    def save
      # noop
    end

    # add reset
    def reset
      targets.synchronize do
        targets.clear
      end
    end
  end
end

# create mock test channel

Inprovise::CmdChannel.define('test') do

  def initialize(node, user=nil)
    @node = node
    @user = user || node.user
  end

  # command execution

  def run(command, forcelog=false)
    @node.log.execute("RUN: #{command}") if Inprovise.verbosity > 0
    "RUN: #{command}"
  end

  # file management

  def upload(from, to)
    @node.log.execute("UPLOAD: #{from} => #{to}") if Inprovise.verbosity > 0
  end

  def download(from, to)
    @node.log.execute("DOWNLOAD: #{from} => #{to}") if Inprovise.verbosity > 0
  end

  def mkdir(path)
    @node.log.execute("MKDIR: #{path}") if Inprovise.verbosity > 0
  end

  def exists?(path)
    @node.log.execute("EXISTS?: #{path}") if Inprovise.verbosity > 0
    true
  end

  def file?(path)
    @node.log.execute("FILE?: #{path}") if Inprovise.verbosity > 0
    true
  end

  def directory?(path)
    @node.log.execute("DIRECTORY?: #{path}") if Inprovise.verbosity > 0
    true
  end

  def content(path)
    @node.log.execute("READ: #{path}") if Inprovise.verbosity > 0
    "READ: #{path}"
  end

  def delete(path)
    @node.log.execute("DELETE: #{path}") if Inprovise.verbosity > 0
  end

  def permissions(path)
    @node.log.execute("PERMISSIONS: #{path}") if Inprovise.verbosity > 0
    0
  end

  def set_permissions(path, perm)
    @node.log.execute("SETPERMISSIONS: #{path} #{perm}") if Inprovise.verbosity > 0
  end

  def owner(path)
    @node.log.execute("OWNER: #{path}") if Inprovise.verbosity > 0
    {:user => @user, :group => 'users'}
  end

  def set_owner(path, user, group=nil)
    @node.log.execute("SET_OWNER: #{path} #{user} #{group}") if Inprovise.verbosity > 0
  end

end

# create mock test helper

Inprovise::CmdHelper.define('test') do

  def initialize(channel, sudo=false)
    super(channel)
  end

  # platform properties

  def admin_user
    'root'
  end

  def env_reference(varname)
    "\$#{varname}"
  end

  # generic command execution

  def sudo
    return self
  end

  # basic commands

  def echo(arg)
    run("echo #{arg}")
  end

  def cat(path)
    begin
      @channel.content(path)
    rescue
      run("cat #{path}")
    end
  end

  def hash_for(path)
    Digest::SHA1.hexdigest(run("sha1sum #{path}"))
  end

  def mkdir(path)
    run("mkdir -p #{path}")
  end

  def exists?(path)
    begin
      @channel.exists?(path)
    rescue
      run(%{if [ -f #{path} ]; then echo "true"; else echo "false"; fi}).strip == 'true'
    end
  end

  def file?(path)
    begin
      @channel.file?(path)
    rescue
      (run("stat --format=%f #{path}").chomp.hex & 0x8000) == 0x8000
    end
  end

  def directory?(path)
    begin
      @channel.file?(path)
    rescue
      (run("stat --format=%f #{path}").chomp.hex & 0x4000) == 0x4000
    end
  end

  def copy(from, to)
    run("cp #{from} #{to}")
  end

  def delete(path)
    begin
      @channel.delete(path)
    rescue
      run("rm #{path}")
    end
  end

  def permissions(path)
    begin
      @channel.permissions(path)
    rescue
      run("stat --format=%a #{path}").strip.to_i(8)
    end
  end

  def set_permissions(path, perm)
    begin
      @channel.set_permissions(path, perm)
    rescue
      run("chmod -R #{sprintf("%o",perm)} #{path}")
    end
  end

  def owner(path)
    begin
      @channel.owner(path)
    rescue
      user, group = run("stat --format=%U:%G #{path}").chomp.split(":")
      {:user => user, :group => group}
    end
  end

  def set_owner(path, user, group=nil)
    begin
      @channel.set_owner(path, user, group)
    rescue
      run(%{chown -R #{user}#{group ? ":#{group}" : ''} #{path}})
    end
  end

  def binary_exists?(bin)
    run("which #{bin}") =~ /\/#{bin}/
  end

end

