# SSH Command channel for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'net/ssh'
require 'net/sftp'
require 'digest/sha1'

# :nocov:

Inprovise::CmdChannel.define('ssh') do

  def initialize(node)
    super(node)
    @connection = nil
    @sftp = nil
  end

  def close
    disconnect
  end

  # command execution

  def run(command, forcelog=false)
    execute(command, forcelog)
  end

  # file management

  def upload(from, to)
    @node.log.remote("SFTP.UPLOAD: #{from} => #{to}") if Inprovise.verbosity > 1
    sftp.upload!(from, to)
  end

  def download(from, to)
    @node.log.remote("SFTP.DOWNLOAD: #{to} <= #{from}") if Inprovise.verbosity > 1
    sftp.download!(from, to)
  end

  def mkdir(path)
    @node.log.remote("SFTP.MKDIR: #{path}") if Inprovise.verbosity > 1
    sftp.mkdir!(path)
  end

  def path_check(path, type=nil)
    begin
      stat = sftp.stat!(path)
      stat != nil && (type.nil? || stat.symbolic_type == type)
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      false
    end
  end
  private :path_check

  def exists?(path)
    @node.log.remote("SFTP.EXISTS?: #{path}") if Inprovise.verbosity > 1
    path_check(path)
  end

  def file?(path)
    @node.log.remote("SFTP.FILE?: #{path}") if Inprovise.verbosity > 1
    path_check(path, :regular)
  end

  def directory?(path)
    @node.log.remote("SFTP.DIRECTORY?: #{path}") if Inprovise.verbosity > 1
    path_check(path, :directory)
  end

  def content(path)
    @node.log.remote("SFTP.READ: #{path}") if Inprovise.verbosity > 1
    sftp.file.open(path) do |io|
      return io.read
    end
  end

  def delete(path)
    @node.log.remote("SFTP.DELETE: #{path}") if Inprovise.verbosity > 1
    sftp.delete!(path) if exists?(path)
  end

  def permissions(path)
    @node.log.remote("SFTP.PERMISSIONS: #{path}") if Inprovise.verbosity > 1
    begin
      sftp.stat!(path).permissions & 0x0FFF
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      0
    end
  end

  def set_permissions(path, perm)
    @node.log.remote("SFTP.SETPERMISSIONS: #{path} #{'%o' % perm}") if Inprovise.verbosity > 1
    sftp.setstat!(path, :permissions => perm)
  end

  def owner(path)
    @node.log.remote("SFTP.OWNER: #{path}") if Inprovise.verbosity > 1
    begin
      result = sftp.stat!(path)
      {:user => result.owner, :group => result.group}
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      nil
    end
  end

  def set_owner(path, user, group=nil)
    @node.log.remote("SFTP.SET_OWNER: #{path} #{user} #{group}") if Inprovise.verbosity > 1
    attrs = { :owner => user }
    attrs.merge({ :group => group }) if group
    sftp.setstat!(path, attrs)
  end

  private

  def options_for_ssh
    opts = [
      :auth_methods, :compression, :compression_level, :config, :encryption , :forward_agent , :global_known_hosts_file ,
      :hmac , :host_key , :host_key_alias , :host_name, :kex , :keys , :key_data , :keys_only , :logger , :paranoid ,
      :passphrase , :password , :port , :properties , :proxy , :rekey_blocks_limit , :rekey_limit , :rekey_packet_limit ,
      :timeout , :user , :user_known_hosts_file , :verbose ]
    ssh_cfg  = @node.config.reduce({}) do |hsh, (k,v)|
      hsh[k] = v if opts.include?(k)
      hsh
    end
    (@node.config[:credentials] || {}).reduce(ssh_cfg) do |hsh, (k,v)|
      hsh[k] = v if k == :password || k == :passphrase
      hsh
    end
  end

  def execute(cmd, forcelog=false)
    @node.log.remote("SSH: #{cmd}") if Inprovise.verbosity > 1 || forcelog
    output = ''
    begin
      connection.exec! cmd do |_channel, stream, data|
        output << data if stream == :stdout
        @node.log.send(stream, data, forcelog) if Inprovise.verbosity > 1 || forcelog
      end
    rescue Net::SSH::Exception => ex
      raise Inprovise::CmdChannel::Exception, "#{ex.message}"
    ensure
      @node.log.flush_all if Inprovise.verbosity > 1 || forcelog
    end
    output
  end

  def connection
    return @connection if @connection && !@connection.closed?
    @connection = Net::SSH.start(@node.host, @node.user, options_for_ssh)
  end

  def disconnect
    @connection.close if @connection && !@connection.closed?
  end

  def sftp
    @sftp ||= connection.sftp.connect
  end

end

# :nocov:

