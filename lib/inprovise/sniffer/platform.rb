# Platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.sniffer('platform') do

  action('(unknown)') do |attrs|
  end

  action('windows') do |attrs|
    # check for Cygwin environment
    ostype = node.channel.run('echo $OSTYPE').strip
    # configure the Linux command helper here first;
    # this way we can use the full context functionality from now on
    node.config[:helper] = (/cygwin/i =~ ostype ? 'cygwin' : 'windows')

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

  action('linux') do |attrs|
    # configure the Linux command helper here first;
    # this way we can use the full context functionality from now on
    node.config[:helper] = 'linux'

    attrs[:machine] = run('uname -m').chomp
    if remote('/etc/os-release').exists?
      trigger 'sniff[platform]:os-release', attrs
    elsif remote('/etc/redhat-release').exists?
      trigger 'sniff[platform]:redhat-release', attrs
    elsif remote('/etc/SuSE-release').exists?
      trigger 'sniff[platform]:suse-release', attrs
    end
    attrs[:pkgman] = case attrs[:os]
                     when 'fedora', 'centos', 'rhel'
                       binary_exists?('dnf') ? 'dnf' : 'yum'
                     when /suse/
                       'zypper'
                     end
  end

  action('os-release') do |attrs|
    data = remote('/etc/os-release').content.split("\n").collect {|l| l.strip }
    vars = data.inject({}) do |hash, line|
      unless line.empty? || line.start_with?('#') || !(line =~ /[^=]+=.*/)
        var, val = line.split('=')
        hash[var] = val.strip.gsub(/(\A")|("\Z)/, '')
      end
      hash
    end
    attrs[:'os-distro'] = vars['ID'].downcase
    attrs[:'os-version'] = vars['VERSION_ID']
    if attrs[:'os-distro'] == 'centos' && remote('/etc/centos-release').exists?
      data = remote('/etc/centos-release').content.split("\n").collect {|l| l.strip }
      data.each do |line|
        if line =~ /\s+release\s+(\d+)\.(\d+).*/
          attrs[:'os-version'] = "#{$1}.#{$2}"
        end
      end
    end
  end

  action('redhat-release') do |attrs|
    data = remote('/etc/redhat-release').content.split("\n").collect {|l| l.strip }
    data.each do |line|
      if line =~ /\A(.+)\s+release\s+(\d+)(\.(\d+))?/
        attrs[:'os-version'] = "#{$2}.#{$4 || '0'}"
        tmpos = $1.strip.downcase
        attrs[:'os-distro'] = case tmpos
                              when /fedora/
                                'fedora'
                              when /red\s+hat/
                                'rhel'
                              when /centos/
                                'centos'
                              end
      end
    end
  end

  action('suse-release') do |attrs|
    data = remote('/etc/SuSE-release').content.split("\n").collect {|l| l.strip }
    attrs[:'os-distro'] = data.shift.split(' ').first.downcase
    data.each do |l|
      if data =~ /\AVERSION\s*=\s*(.*)/i
        attrs[:'os-version'] = $1.strip
      end
    end
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
                   '(unknown)'
                 end
    trigger "sniff[platform]:#{attrs[:os]}", attrs
    (node.config[:attributes][:platform] ||= {}).merge!(attrs)
  end

end
