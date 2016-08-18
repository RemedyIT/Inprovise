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
    @template.render(@context, locals)
  end

  def render_to_tempfile(locals={})
    basename = @path.respond_to?(:call) ? 'inprovise-inline-tpl' : File.basename(@path).gsub('.', '-')
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
