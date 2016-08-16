# Platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.sniffer('platform') do

  action('linux') do |attrs|
    if remote('/etc/os-release').exists?
      trigger 'platform:os-release', attrs
    elsif remote('/etc/redhat-release').exists?
      trigger 'platform:redhat-release', attrs
    elsif remote('/etc/SuSE-release').exists?
      trigger 'platform:suse-release', attrs
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
    attrs[:os] = vars['ID'].downcase
    attrs[:'os-version'] = vars['VERSION_ID']
    if attrs[:os] == 'centos' && remote('/etc/centos-release').exists?
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
        attrs[:os] = case tmpos
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
    attrs[:os] = data.shift.split(' ').first.downcase
    data.each do |l|
      if data =~ /\AVERSION\s*=\s*(.*)/i
        attrs[:'os-version'] = $1.strip
      end
    end
  end

  apply do
    # for now assume *nix platform
    attrs = {}
    attrs[:machine] = run('uname -m').strip
    ostype = run('uname -o').strip
    attrs[:os] = '(unknown)'
    case ostype
    when /linux/i
      trigger 'platform:linux', attrs
    end
    (node.config[:attributes][:platform] ||= {}).merge!(attrs)
  end

end
