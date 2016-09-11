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
    streambuf = buffer(stream)
    while lnbuf = streambuf.shift
      clear_to_eol = lnbuf[:cr]
      lnbuf[:ln].scan(/([^\r]*)(\r)?/) do |txt, cr|
        # do we have a (full) line to print?
        if cr || !streambuf.empty?
          out = lnbuf[:col] ? txt.to_s.send(lnbuf[:col]) : txt
          unless txt.empty?
            ios(stream).print "\r".to_eol if clear_to_eol
            ios(stream).print "#{@node.to_s} [#{@task.bold}] #{out}"
          end
          ios(stream).flush if cr
          ios(stream).puts unless cr || (txt.empty? && !clear_to_eol)
          clear_to_eol = cr ? true : false
          break unless cr # next line or cr?
        else
          streambuf << if txt.empty?
            # restart with empty line
            {col:nil,ln:'',cr:clear_to_eol}
          else
            # stuff the remaining text back for a next round
            {col:lnbuf[:col],ln:txt,cr:clear_to_eol}
          end
          return
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
