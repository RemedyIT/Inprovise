# Windows platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.define('windows', false) do

  action('main') do |attrs|
    attrs[:machine] = env('PROCESSOR_ARCHITECTURE').chomp =~ /amd64/i ? 'x86_64' : 'x86'
    osver = run('cmd /c ver').strip
    if /\[version\s+(\d+)\.(\d+)\.(\d+)\]/i =~ osver
      attrs[:'os-version'] = case $1
                               when '5'
                               'xp'
                               when '6'
                                 case $2
                                   when '1'
                                     '7'
                                   when '2'
                                     '8'
                                   when '3'
                                     '8.1'
                                 end
                               when '10'
                                 '10'
                               else
                                 $1
                             end
    end
  end

end
