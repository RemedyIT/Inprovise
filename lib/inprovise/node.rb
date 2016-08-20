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

  def method_missing(meth, *args)
    get(meth)
  end

  def channel
    @channel ||= Inprovise::CmdChannel.open(self, config[:channel])
  end

  def helper
    @helper ||= Inprovise::CmdHelper.get(self, config[:helper])
  end

  # generic command execution

  def run(cmd, opts={})
    if should_run?(cmd, opts)
      really_run(cmd, opts)
    else
      cached_run(cmd, opts)
    end
  end

  def sudo(cmd, opts={})
    opts = opts.merge({:sudo => true})
    if should_run?(cmd, opts)
      really_run(cmd, opts)
    else
      cached_run(cmd, opts)
    end
  end

  # file management

  def upload(from, to)
    log.execute("UPLOAD: #{from} => #{to}")
    helper.upload(from, to)
  end

  def download(from, to)
    log.execute("DOWLOAD: #{from} => #{to}")
    helper.download(from, to)
  end

  # basic commands

  def echo(arg)
    helper.echo(arg)
  end

  def env(var)
    helper.env(var)
  end

  def cat(path)
    helper.cat(path)
  end

  def hash_for(path)
    helper.hash_for(path)
  end

  def mkdir(path)
    helper.mkdir(path)
  end

  def exists?(path)
    helper.exists?(path)
  end

  def file?(path)
    helper.file?(path)
  end

  def directory?(path)
    helper.directory?(path)
  end

  def copy(from, to)
    helper.copy(from, to)
  end

  def delete(path)
    helper.delete(path)
  end

  def permissions(path)
    helper.permissions(path)
  end

  def set_permissions(path, perm)
    helper.set_permissions(path, perm)
  end

  def owner(path)
    helper.owner(path)
  end

  def group(path)
    helper.group(path)
  end

  def set_owner(path, user, group=nil)
    helper.set_owner(path, user, group=nil)
  end

  def binary_exists?(bin)
    helper.binary_exists?(bin)
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
    exec = opts[:sudo] ? helper : helper.sudo
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
