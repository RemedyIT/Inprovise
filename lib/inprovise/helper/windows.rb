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

  def hash_for(path)
    Digest::SHA1.hexdigest(cat(path))
  end

  def mkdir(path)
    run("mkdir #{path}")    # assumes CMD extensions are enabled
  end

  def exists?(path)
    begin
      @channel.exists?(path)
    rescue
      run(%{if exist #{path} ] (echo true) else (echo false)}).strip == 'true'
    end
  end

  def file?(path)
    begin
      @channel.file?(path)
    rescue
      !run("for %p in (#{path}) do echo %~ap-").chomp.start_with?('d')
    end
  end

  def directory?(path)
    begin
      @channel.file?(path)
    rescue
      run("for %p in (#{path}) do echo %~ap-").chomp.start_with?('d')
    end
  end

  def copy(from, to)
    run("copy #{from} #{to}")
  end

  def delete(path)
    begin
      @channel.delete(path)
    rescue
      run("del #{path}")
    end
  end

  def permissions(path)
    begin
      @channel.permissions(path)
    rescue
      # not implemented yet
      0
    end
  end

  def set_permissions(path, perm)
    begin
      @channel.set_permissions(path, perm)
    rescue
      # not implemented yet
    end
  end

  def owner(path)
    begin
      @channel.owner(path)
    rescue
      # not implemented yet
      {:user => nil, :group => nil}
    end
  end

  def set_owner(path, user, group=nil)
    begin
      @channel.set_owner(path, user, group)
    rescue
      # not implemented yet
    end
  end

  def binary_exists?(bin)
    run(%{for %p in (#{bin}) do (if exist "%~$PATH:p" echo %~$PATH:p)}).chomp =~ /#{bin}/
  end

end
