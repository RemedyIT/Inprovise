# CLI-test helper for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

require_relative './test_helper'

# prevent CLI error handling from exiting
class Inprovise::Cli
  on_error do |exception|
    # Error logic here
    # return false to skip default error handling
    $stderr.puts "ERROR: #{exception.message}".red
    if Inprovise.verbosity > 0
      $stderr.puts "#{exception}\n#{exception.backtrace.join("\n")}"
    end
    true
  end
end
