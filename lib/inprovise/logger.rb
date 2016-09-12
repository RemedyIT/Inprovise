# Logger for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'monitor'

class Inprovise::Logger
  attr_accessor :node
  attr_reader :task

  class << self
    def streams
      @streams ||= ::Hash.new.extend(::MonitorMixin).merge!({
        :stdout => { :ios => $stdout, :buffer => [{col: nil, ln: '', cr: false}] },
        :stderr => { :ios => $stderr, :buffer => [{col: nil, ln: '', cr: false}] }
      })
    end
  end

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

  def log(msg, color=nil)
    say(msg, color)
  end

  def synchronize(&block)
    self.class.streams.synchronize do
      block.call
    end if block_given?
  end
  private :synchronize

  def ios(stream=:stdout)
    self.class.streams[stream][:ios]
  end
  private :ios

  def buffer(stream=:stdout)
    self.class.streams[stream][:buffer]
  end
  private :buffer

  def next_line(stream)
    lnbuf = buffer(stream).shift || {}
    [lnbuf[:col], lnbuf[:ln], lnbuf[:cr]]
  end
  private :next_line

  def push_line(stream, col, ln, cr)
    buffer(stream) << {col: col, ln: ln, cr: cr ? true : false}
  end
  private :push_line

  def put(msg, color=nil, stream=:stdout)
    streambuf = buffer(stream)
    streambuf.last[:col] ||= color
    streambuf.last[:ln] << msg
    streambuf
  end
  private :put

  def puts(msg, color=nil, stream=:stdout)
    put(msg, color, stream) << {col:nil, ln:'',cr:false}
  end
  private :puts

  def do_print(stream=:stdout)
    until buffer(stream).empty?
      col, ln, cr_at_start = next_line(stream)
      ln.scan(/([^\r]*)(\r)?/) do |txt, cr|
        nl = buffer(stream).size > 0
        if cr || nl
          unless txt.empty?
            out = col ? txt.to_s.send(col) : txt
            ios(stream).print "\r".to_eol if cr_at_start
            ios(stream).print "#{@node} [#{@task.bold}] #{out}"
          end
          if cr
            ios(stream).flush
          else
            ios(stream).puts unless txt.empty? && !cr_at_start
          end
          cr_at_start = cr
        else
          # cache for later
          push_line(stream, txt.empty? ? nil : col, txt, cr_at_start)
          return # done printing for now
        end
      end
    end
  end
  private :do_print

  def do_flush(stream)
    lnbuf = buffer(stream).last
    unless lnbuf[:ln].empty? && !lnbuf[:cr]
      # add an empty line buffer to force output of current buffered contents
      buffer(stream) << {col:nil, ln:'',cr:false}
      do_print(stream)
    end
  end
  private :do_flush

  def flush(stream=:stdout)
    synchronize do
      do_flush(stream)
    end
    self
  end

  def flush_all
    synchronize do
      [:stderr, :stdout].each { |stream| do_flush(stream) }
    end
    self
  end

  def print(msg, color=nil, stream=:stdout)
    synchronize do
      put(msg, color, stream)
      do_print(stream)
    end
    self
  end

  def println(msg, color=nil, stream=:stdout)
    synchronize do
      puts(msg, color, stream)
      do_print(stream)
    end
    self
  end

  def redirect(msg, color, stream)
    synchronize do
      msg.to_s.scan(/([^\n]*)(\n\r|\n)?/) do |txt,sep|
        if sep
          puts(txt, color, stream)
        else
          put(txt, color, stream)
        end
        break unless sep
      end
      do_print(stream)
    end
    self
  end
  private :redirect

  def stdout(msg, force=false)
    redirect(msg, :green, :stdout) if force || Inprovise.verbosity>0
  end

  def stderr(msg, force=false)
    redirect(msg, :red, :stderr) if force || Inprovise.verbosity>0
  end

  def say(msg, color=nil, stream=:stdout)
    synchronize do
      [:stderr, :stdout].each { |stream| do_flush(stream) }
      streambuf = buffer(stream)
      msg.to_s.scan(/([^\n]*)(\n\r|\n)?/) do |txt,sep|
        puts(txt)
        break unless sep
      end
      do_print(stream)
    end
    self
  end
end
