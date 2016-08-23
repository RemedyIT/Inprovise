# Infrastructure node for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'json'

class Inprovise::Infrastructure::Node < Inprovise::Infrastructure::Target
  attr_reader :host, :user

  def initialize(name, config={})
    @host = config[:host] || name
    @user = config[:user] || 'root'
    @channel = nil
    @helper = nil
    @history = []
    @user_nodes = {}
    super(name, config)
  end

  def channel
    @channel ||= Inprovise::CmdChannel.open(self, config[:channel])
  end

  def helper
    @helper ||= Inprovise::CmdHelper.get(self, config[:helper])
  end

  def disconnect!
    @user_nodes.each_value {|n| n.disconnect! }
    @channel.close
    self
  end

  # generic command execution

  def run(cmd, opts={})
    log.execute("RUN: #{cmd}") if Inprovise.verbosity > 0
    if should_run?(cmd, opts)
      really_run(cmd, opts)
    else
      cached_run(cmd, opts)
    end
  end

  def sudo(cmd, opts={})
    log.execute("SUDO: #{cmd}") if Inprovise.verbosity > 0
    opts = opts.merge({:sudo => true})
    if should_run?(cmd, opts)
      really_run(cmd, opts)
    else
      cached_run(cmd, opts)
    end
  end

  # file management

  def upload(from, to)
    log.execute("UPLOAD: #{from} => #{to}") if Inprovise.verbosity > 0
    helper.upload(from, to)
  end

  def download(from, to)
    log.execute("DOWLOAD: #{to} <= #{from}") if Inprovise.verbosity > 0
    helper.download(from, to)
  end

  # basic commands

  def echo(arg)
    log.execute("ECHO: #{arg}") if Inprovise.verbosity > 0
    out = helper.echo(arg)
    log.execute("ECHO: #{out}") if Inprovise.verbosity > 0
    out
  end

  def env(var)
    log.execute("ENV: #{var}") if Inprovise.verbosity > 0
    val = helper.env(var)
    log.execute("ENV: #{val}") if Inprovise.verbosity > 0
    val
  end

  def cat(path)
    log.execute("CAT: #{path}") if Inprovise.verbosity > 0
    out = helper.cat(path)
    log.execute("CAT: #{out}") if Inprovise.verbosity > 0
    out
  end

  def hash_for(path)
    log.execute("HASH_FOR: #{path}") if Inprovise.verbosity > 0
    hsh = helper.hash_for(path)
    log.execute("HASH_FOR: #{hsh}") if Inprovise.verbosity > 0
    hsh
  end

  def mkdir(path)
    log.execute("MKDIR: #{path}") if Inprovise.verbosity > 0
    helper.mkdir(path)
  end

  def exists?(path)
    log.execute("EXISTS?: #{path}") if Inprovise.verbosity > 0
    rc = helper.exists?(path)
    log.execute("EXISTS?: #{rc}") if Inprovise.verbosity > 0
    rc
  end

  def file?(path)
    log.execute("FILE?: #{path}") if Inprovise.verbosity > 0
    rc = helper.file?(path)
    log.execute("FILE?: #{rc}") if Inprovise.verbosity > 0
    rc
  end

  def directory?(path)
    log.execute("DIRECTORY?: #{path}") if Inprovise.verbosity > 0
    rc = helper.directory?(path)
    log.execute("DIRECTORY?: #{rc}") if Inprovise.verbosity > 0
    rc
  end

  def copy(from, to)
    log.execute("COPY: #{from} #{to}") if Inprovise.verbosity > 0
    helper.copy(from, to)
  end

  def delete(path)
    log.execute("DELETE: #{path}") if Inprovise.verbosity > 0
    helper.delete(path)
  end

  def permissions(path)
    log.execute("PERMISSIONS: #{path}") if Inprovise.verbosity > 0
    perm = helper.permissions(path)
    log.execute("PERMISSIONS: #{'%o' % perm}") if Inprovise.verbosity > 0
    perm
  end

  def set_permissions(path, perm)
    log.execute("SET_PERMISSIONS: #{path} #{'%o' % perm}") if Inprovise.verbosity > 0
    helper.set_permissions(path, perm)
  end

  def owner(path)
    log.execute("OWNER: #{path}") if Inprovise.verbosity > 0
    owner = helper.owner(path)
    log.execute("OWNER: #{owner}") if Inprovise.verbosity > 0
    owner
  end

  def group(path)
    log.execute("GROUP: #{path}") if Inprovise.verbosity > 0
    group = helper.group(path)
    log.execute("OWNER: #{group}") if Inprovise.verbosity > 0
    group
  end

  def set_owner(path, user, group=nil)
    log.execute("SET_OWNER: #{path} #{user}#{group ? " #{group}" : ''}") if Inprovise.verbosity > 0
    helper.set_owner(path, user, group)
  end

  def binary_exists?(bin)
    log.execute("BINARY_EXISTS?: #{bin}") if Inprovise.verbosity > 0
    rc = helper.binary_exists?(bin)
    log.execute("BINARY_EXISTS?: #{rc}") if Inprovise.verbosity > 0
    rc
  end

  def log
    @log ||= Inprovise::Logger.new(self, nil)
  end

  def log_to(log)
    @log = log
  end

  def for_user(new_user)
    new_user = new_user.to_s
    return self if self.user == new_user
    return @user_nodes[new_user] if @user_nodes[new_user]
    new_node = self.dup
    new_node.prepare_connection_for_user!(new_user)
    @user_nodes[new_user] = new_node
    new_node
  end

  def prepare_connection_for_user!(new_user)
    @user = new_user
    @channel = nil
    @helper = nil
    @user_nodes = {}
    @history = []
  end

  def to_s
    "#{name}(#{user}@#{host})"
  end

  def safe_config
    scfg = config.dup
    scfg.delete :passphrase
    scfg.delete :password
    scfg.delete :credentials
    scfg
  end
  protected :safe_config

  def to_json(*a)
    {
      JSON.create_id  => self.class.name,
      :data => {
        :name => name,
        :config => safe_config
      }
    }.to_json(*a)
  end

  def self.json_create(o)
    data = o[:data]
    new(data[:name], data[:config])
  end

  private

  def cached_run(cmd, opts={})
    cmd = "sudo #{cmd}" if opts[:sudo]
    log.cached(cmd)
    last_output(cmd)
  end

  def really_run(cmd, opts={})
    exec = opts[:sudo] ? helper.sudo : helper
    cmd = prefixed_command(cmd)
    begin
      output = exec.run(cmd, opts[:log])
      @history << {cmd:cmd, output:output}
      output
    rescue Exception
      raise RuntimeError, "Failed to communicate with [#{self.to_s}]"
    end
  end

  def should_run?(cmd, opts)
    return true unless opts[:once]
    cmd = "sudo #{cmd}" if opts[:sudo]
    last_output(cmd).nil?
  end

  def last_output(cmd)
    results = @history.select {|h| h[:cmd] == cmd }
    return nil unless results && results.size > 0
    results.last[:output]
  end

  def prefixed_command(cmd)
    return cmd unless config[:prefix]
    config[:prefix] + cmd
  end
end
