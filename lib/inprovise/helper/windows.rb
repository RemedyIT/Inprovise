# Windows Command helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'digest/sha1'

Inprovise::CmdHelper.define('windows') do

  # platform properties

  def admin_user
    'administrator'
  end

  def env_reference(varname)
    "%#{varname}%"
  end

  # generic command runution

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
      run("type #{path}")
    end
  end

  def hash(path)
    Digest::SHA1.hexdigest(cat(path))
  end

  def mkdir(path)
    run("mkdir #{path}")    # assumes CMD extensions are enabled
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
