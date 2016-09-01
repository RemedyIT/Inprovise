# Logger for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Logger
  attr_accessor :node
  attr_reader :task

  def initialize(node, task)
    @node = node
    @nl = true
    set_task(task)
  end

  def clone_for_node(node)
    copy = self.dup
    copy.node = node
    copy
  end

  def set_task(task)
    oldtask = @task
    @task = task.to_s
    oldtask
  end

  def command(msg)
    say(msg, :yellow)
  end

  def local(cmd)
    say(cmd, :bold)
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

  def remote(cmd)
    say(cmd, :blue)
  end

  def log(msg)
    say(msg)
  end

  def print(msg)
    Thread.exclusive do
      $stdout.print "#{@node.to_s} [#{@task.bold}] " if @nl
      $stdout.print msg.sub("\r", "\r".to_eol << "#{@node.to_s} [#{@task.bold}] ")
    end
    @nl = false
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
      Thread.exclusive { stream.puts unless @nl; stream.puts "#{@node.to_s} [#{@task.bold}] #{out}" }
      @nl = true
    end
  end
end
