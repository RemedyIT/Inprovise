# SSH Command channel for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'net/ssh'
require 'net/sftp'
require 'digest/sha1'

Inprovise::CmdChannel.define('ssh') do

  def initialize(node, user=nil)
    @node = node
    @user = user || node.user
    @connection = nil
    @sftp = nil
    if @node.config.has_key?(:credentials) && @node.config[:credentials].has_key?(:'public-key')
      install_pubkey(@node.config[:credentials][:'public-key'])
    end
  end

  # command execution

  def run(command, forcelog=false)
    execute(command, forcelog)
  end

  # file management

  def upload(from, to)
    @node.log.execute("UPLOAD: #{from} => #{to}") if Inprovise.verbosity > 0
    sftp.upload!(from, to)
  end

  def download(from, to)
    @node.log.execute("DOWNLOAD: #{from} => #{to}") if Inprovise.verbosity > 0
    sftp.download!(from, to)
  end

  def mkdir(path)
    @node.log.execute("MKDIR: #{path}") if Inprovise.verbosity > 0
    sftp.mkdir!(path)
  end

  def exists?(path)
    @node.log.execute("EXISTS?: #{path}") if Inprovise.verbosity > 0
    begin
      sftp.stat!(path) != nil
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      false
    end
  end

  def file?(path)
    @node.log.execute("FILE?: #{path}") if Inprovise.verbosity > 0
    begin
      sftp.stat!(path).symbolic_type == :regular
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      false
    end
  end

  def directory?(path)
    @node.log.execute("DIRECTORY?: #{path}") if Inprovise.verbosity > 0
    begin
      sftp.stat!(path).symbolic_type == :directory
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      false
    end
  end

  def content(path)
    @node.log.execute("READ: #{path}") if Inprovise.verbosity > 0
    sftp.file.open(path) do |io|
      return io.read
    end
  end

  def delete(path)
    @node.log.execute("DELETE: #{path}") if Inprovise.verbosity > 0
    sftp.delete!(path) if exists?(path)
  end

  def permissions(path)
    @node.log.execute("PERMISSIONS: #{path}") if Inprovise.verbosity > 0
    begin
      sftp.stat!(path).permissions == 0x0FFF
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      0
    end
  end

  def set_permissions(path, perm)
    @node.log.execute("SETPERMISSIONS: #{path} #{perm}") if Inprovise.verbosity > 0
    sftp.setstat!(path, :permissions => perm)
  end

  def owner(path)
    @node.log.execute("OWNER: #{path}") if Inprovise.verbosity > 0
    begin
      result = sftp.stat!(path)
      {:user => result.owner, :group => result.group}
    rescue Net::SFTP::StatusException => ex
      raise ex unless ex.code == Net::SFTP::Response::FX_NO_SUCH_FILE
      nil
    end
  end

  def set_owner(path, user, group=nil)
    @node.log.execute("SET_OWNER: #{path} #{user} #{group}") if Inprovise.verbosity > 0
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

  def install_pubkey(pubkey_path)
    log_bak = @node.log
    begin
      @node.log_to(Inprovise::Logger.new(@node, 'ssh[init]'))
      unless exists?('./.ssh')
        mkdir('./.ssh')
        set_permissions('./.ssh', 755)
      end
      begin
        @node.log.execute("APPEND: #{pubkey_path} -> ./.ssh/authorized_keys") if Inprovise.verbosity > 0
        sftp.file.open('./.ssh/authorized_keys', 'a') do |f|
          f.puts File.read(pubkey_path)
        end
      rescue
        # using the SFTP option failed, let's try a more basic approach
        upload_path = "inprovise-upload-#{Digest::SHA1.file(pubkey_path).hexdigest}"
        upload(pubkey_path, upload_path)
        run("cat #{upload_path} >> ./.ssh/authorized_keys")
        run("rm #{upload_path}")
      end
      set_permissions('./.ssh/authorized_keys', 644)
    ensure
      @node.log_to(log_bak)
    end
  end

  def execute(cmd, forcelog=false)
    @node.log.execute(cmd.cyan) if Inprovise.verbosity > 0 || forcelog
    output = ''
    connection.exec! cmd do |channel, stream, data|
      output << data if stream == :stdout
      data.split("\n").each do |line|
        @node.log.send(stream, line, forcelog)
      end if Inprovise.verbosity > 1 || forcelog
    end
    output
  end

  def connection
    return @connection if @connection && !@connection.closed?
    @connection = Net::SSH.start(@node.host, @user, options_for_ssh)
  end

  def disconnect
    @connection.close if @connection && !@connection.closed?
  end

  def sftp
    @sftp ||= connection.sftp.connect
  end

end
