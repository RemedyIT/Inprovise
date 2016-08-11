# Logger for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Logger
  attr_accessor :node

  def initialize(node, task)
    @node = node
    set_task(task)
  end

  def clone_for_node(node)
    copy = self.dup
    copy.node = node
    copy
  end

  def set_task(task)
    @task = task.to_s
  end

  def command(msg)
    say(msg, :yellow)
  end

  def local(cmd)
    say(cmd, :cyan)
  end

  def execute(cmd)
    say(cmd, :cyan)
  end

  def mock_execute(cmd)
    execute(cmd)
  end

  def cached(cmd)
    execute(cmd)
  end

  def sftp(cmd)
    execute(cmd)
  end

  def log(msg)
    say(msg)
  end

  def stdout(msg, force=false)
    say(msg, :green) if force || Inprovise.verbosity>0
  end

  def stderr(msg, force=false)
    say(msg, :red, $stderr) if force || Inprovise.verbosity>0
  end

  def say(msg, color=nil, stream=$stdout)
    msg.to_s.split("\n").each do |line|
      out = color ? line.send(color) : line
      Thread.exclusive { stream.puts "#{@node.to_s} [#{@task.bold}] #{out}" }
    end
  end
end
