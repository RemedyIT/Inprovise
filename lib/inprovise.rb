# Main loader for inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require 'rubygems'
require 'colored'

module Inprovise
  def verbosity(val=nil)
    @verbose = val unless val.nil?
    @verbose || 0
  end
  module_function :verbose

  def root
    File.dirname(ENV['INPROVISE_RC'])
  end
  module_function :root


end
