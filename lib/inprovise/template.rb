# Template support for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require 'erb'
require 'tilt'
require 'tempfile'

class Inprovise::Template
  def initialize(path, context = nil)
    @context = context || Object.new
    @path = resolve(path)
    @template = @path.respond_to?(:call) ? Tilt['erb'].new(&@path) : Tilt.new(@path)
  end

  def render(locals={})
    @template.render(Inprovise::ExecutionContext::DSL.new(@context), locals)
  end

  def render_to(fname, *opts, &block)
    locals = Hash === opts.last ? opts.pop : {}
    mktmp = (opts.size) > 0 ? opts.shift : true
    tmpfile = @context.local(render_to_tempfile(locals))
    fremote = nil
    begin
      # upload to temporary file
      fremote = tmpfile.upload("#{File.basename(fname, '.*')}-#{tmpfile.hash}#{File.extname(fname)}")
      # move/rename temporary file if required
      unless mktmp && File.dirname(fname) == '.'
        fremote = fremote.move_to(mktmp ? File.dirname(fname) : fname)
      end
      if block_given?
        @context.exec(block, fremote)
        fremote.delete! if mktmp
        fremote = nil
      end
    ensure
      tmpfile.delete!
    end
    fremote
  end

  def render_to_tempfile(locals={})
    basename = @path.respond_to?(:call) ? 'inprovise-inline-tpl' : File.basename(@path).tr('.', '-')
    file = Tempfile.new(basename)
    file.write render(locals)
    file.close
    file.path
  end

  private

  def resolve(path)
    if path.respond_to?(:call) || path =~ /^\//
      path
    else
      File.join(Inprovise.root, path)
    end
  end
end
