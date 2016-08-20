# Platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.define('platform') do

  action('helper') do |attrs|
    # determin the best CmdHelper if not user defined
    attrs[:helper] = case attrs[:os]
                     when 'linux'
                       'linux'
                     when 'windows'
                       # check for Cygwin environment
                       ostype = node.channel.run('echo $OSTYPE').strip
                       # configure the Linux command helper here first;
                       # this way we can use the full context functionality from now on
                       node.config[:helper] = (/cygwin/i =~ ostype ? 'cygwin' : 'windows')
                     end unless attrs[:helper]
  end

  apply do
    attrs = {}
    os = node.channel.run('echo %OS%').chomp
    os = node.channel.run('echo $OS').chomp if os == '%OS%'
    os = node.channel.run('uname -o').chomp if os.empty?
    attrs[:os] = case os
                   when /windows/i
                   'windows'
                   when /linux/i
                   'linux'
                   else
                   'unknown'
                 end
    # determin and initialize helper
    trigger 'sniff[platform]:helper', attrs
    # detect detailed platform props
    trigger "sniff[#{attrs[:os]}]:main", attrs
    (node.config[:attributes][:platform] ||= {}).merge!(attrs)
  end

end

require_relative './windows.rb'
require_relative './linux.rb'
require_relative './unknown.rb'
