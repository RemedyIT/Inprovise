# Linux platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.define('linux', false) do

  action('main') do |attrs|
    attrs[:machine] = run('uname -m').chomp
    if remote('/etc/os-release').exists?
      trigger 'sniff[linux]:os-release', attrs
    elsif remote('/etc/redhat-release').exists?
      trigger 'sniff[linux]:redhat-release', attrs
    elsif remote('/etc/SuSE-release').exists?
      trigger 'sniff[linux]:suse-release', attrs
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

end
