# Infrastructure node for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'net/ssh'
require 'net/sftp'
require 'json'

class Inprovise::Infrastructure::Node < Inprovise::Infrastructure::Target
  attr_reader :host, :user

  def initialize(name, config={})
    @host = config[:host] || name
    @user = config[:user] || 'root'
    @connection = nil
    @history = []
    @user_nodes = {}
    super(name, config)
  end

  def method_missing(meth, *args)
    get(meth)
  end

  def upload(from, to)
    log.sftp("UPLOAD: #{from} => #{to}")
    sftp.upload!(from, to)
  end

  def download(from, to)
    log.sftp("DOWLOAD: #{from} => #{to}")
    sftp.download!(from, to)
  end

  def remove(path)
    log.sftp("REMOVE: #{path}")
    begin
      sftp.remove!(path)
    rescue Net::SFTP::StatusException
      sudo("rm #{path}")
    end
  end

  def stat(path)
    log.sftp("STAT: #{path}")
    sftp.stat!(path)
  end

  def setstat(path, opts)
    log.sftp("SET: #{path} - #{opts.inspect}")
    sftp.setstat!(path, opts)
  end

  def sftp
    @sftp ||= connection.sftp.connect
  end

  def execute(cmd, opts={})
    if should_execute?(cmd, opts)
      really_execute(cmd, opts)
    else
      cached_execute(cmd, opts)
    end
  end

  def sudo(cmd, opts={})
    execute("sudo #{cmd}", opts)
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
    @connection = nil
    @user_nodes = {}
    @history = []
  end

  def connection
    return @connection if @connection && !@connection.closed?
    @connection = Net::SSH.start(@host, (@user), options_for_ssh)
  end

  def disconnect
    @connection.close if @connection && !@connection.closed?
    @user_nodes.values.each {|n| n.disconnect }
  end

  def to_s
    "Node:#{name}(#{user}@#{host})"
  end

  def to_json(*a)
    {
      JSON.create_id  => self.class.name,
      'data' => {
        'name' => name,
        'config' => config
      }
    }.to_json(*a)
  end

  def self.json_create(o)
    data = o['data']
    new(data['name'], data['config'])
  end

  private

  def options_for_ssh
    opts = [:auth_methods, :compression, :compression_level, :config, :encryption , :forward_agent , :global_known_hosts_file , :hmac , :host_key , :host_key_alias , :host_name, :kex , :keys , :key_data , :keys_only , :logger , :paranoid , :passphrase , :password , :port , :properties , :proxy , :rekey_blocks_limit , :rekey_limit , :rekey_packet_limit , :timeout , :user , :user_known_hosts_file , :verbose ]
    config.reduce({}) do |hsh, (k,v)|
      hsh[k] = v if opts.include?(k)
      hsh
    end
  end

  def cached_execute(cmd, opts={})
    log.cached(cmd)
    last_output(cmd)
  end

  def really_execute(cmd, opts={})
    cmd = prefixed_command(cmd)
    log.execute(cmd.cyan) if Inprovise.verbosity > 0
    output = ""
    connection.exec! cmd do |channel, stream, data|
      output += data if stream == :stdout
      data.split("\n").each do |line|
        log.send(stream, line, opts[:log])
      end if Inprovise.verbosity > 1 || opts[:log]
    end
    @history << {cmd:cmd, output:output}
    output
  end

  def should_execute?(cmd, opts)
    return true unless opts[:once]
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
