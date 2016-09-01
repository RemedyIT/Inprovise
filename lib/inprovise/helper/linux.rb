# Linux Command helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::CmdHelper.define('linux') do

  def initialize(channel, sudo=false)
    super(channel)
    @exec = sudo ? :sudo_run : :plain_run
    @cwd = nil
  end

  # platform properties

  def admin_user
    'root'
  end

  def env_reference(varname)
    "\$#{varname}"
  end

  def cwd
    @cwd || plain_run('pwd').chomp
  end

  def set_cwd(path)
    old_cwd = @cwd
    @cwd = path ? File.expand_path(path, self.cwd) : path
    old_cwd
  end

  # generic command execution

  def run(cmd, forcelog=false)
    cmd = "cd #{cwd}; #{cmd}" if @cwd
    exec(cmd, forcelog)
  end

  def sudo
    return self if @exec == :sudo_run
    @sudo ||= self.class.new(@channel, true)
    @sudo.set_cwd(@cwd)
    @sudo
  end

  # file management

  def upload(from, to)
    @channel.upload(real_path(from), real_path(to))
  end

  def download(from, to)
    @channel.download(real_path(from), real_path(to))
  end

  # basic commands

  def echo(arg)
    exec("echo #{arg}")
  end

  def cat(path)
    path = real_path(path)
    begin
      @channel.content(path)
    rescue
      exec("cat #{path}")
    end
  end

  def hash_for(path)
    path = real_path(path)
    exec("sha1sum #{path}")[0...40]
  end

  def mkdir(path)
    path = real_path(path)
    exec("mkdir -p #{path}")
  end

  def exists?(path)
    path = real_path(path)
    begin
      @channel.exists?(path)
    rescue
      exec(%{if [ -f #{path} ]; then echo true; else echo false; fi}).strip == 'true'
    end
  end

  def file?(path)
    path = real_path(path)
    begin
      @channel.file?(path)
    rescue
      (exec("stat --format=%f #{path}").chomp.hex & 0x8000) == 0x8000
    end
  end

  def directory?(path)
    path = real_path(path)
    begin
      @channel.file?(path)
    rescue
      (exec("stat --format=%f #{path}").chomp.hex & 0x4000) == 0x4000
    end
  end

  def copy(from, to)
    exec("cp #{real_path(from)} #{real_path(to)}")
  end

  def move(from, to)
    exec("mv #{real_path(from)} #{real_path(to)}")
  end

  def delete(path)
    path = real_path(path)
    begin
      @channel.delete(path)
    rescue
      exec("rm #{path}")
    end
  end

  def permissions(path)
    path = real_path(path)
    begin
      @channel.permissions(path)
    rescue
      exec("stat --format=%a #{path}").strip.to_i(8)
    end
  end

  def set_permissions(path, perm)
    path = real_path(path)
    begin
      @channel.set_permissions(path, perm)
    rescue
      exec("chmod -R #{sprintf("%o",perm)} #{path}")
    end
  end

  def owner(path)
    path = real_path(path)
    begin
      @channel.owner(path)
    rescue
      user, group = exec("stat --format=%U:%G #{path}").chomp.split(":")
      {:user => user, :group => group}
    end
  end

  def set_owner(path, user, group=nil)
    path = real_path(path)
    begin
      @channel.set_owner(path, user, group)
    rescue
      exec(%{chown -R #{user}#{group ? ":#{group}" : ''} #{path}})
    end
  end

  def binary_exists?(bin)
    exec("which #{bin}") =~ /\/#{bin}/ ? true : false
  end

  private

  def real_path(path)
    return File.expand_path(path, @cwd) if @cwd
    path
  end

  def exec(cmd, forcelog=false)
    send(@exec, cmd, forcelog)
  end

  def plain_run(cmd, forcelog=false)
    @channel.run(cmd, forcelog)
  end

  def sudo_run(cmd, forcelog=false)
    @channel.run(%{sudo sh -c "#{cmd}"}, forcelog)
  end

end
