# Linux platform sniffer for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::Sniffer.define('linux', false) do

  # :nocov:

  action('main') do |attrs|
    attrs[:machine] = run('uname -m').chomp
    if binary_exists?('lsb_release')
      trigger 'sniff[linux]:lsb_release', attrs
    elsif binary_exists?('lsb-release')
      trigger 'sniff[linux]:lsb_release', attrs, 'lsb-release'
    end
    unless attrs[:os_distro]
      if remote('/etc/os-release').exists?
        trigger 'sniff[linux]:os-release', attrs
      elsif remote('/etc/redhat-release').exists?
        trigger 'sniff[linux]:redhat-release', attrs
      elsif remote('/etc/SuSE-release').exists?
        trigger 'sniff[linux]:suse-release', attrs
      elsif remote('/etc/debian-version').exists?
        trigger 'sniff[linux]:debian-version', attrs
      end
    end
    attrs[:pkgman] = case attrs[:os_distro]
      when 'fedora', 'centos', 'rhel'
      binary_exists?('dnf') ? 'dnf' : 'yum'
      when 'linuxmint', 'ubuntu', 'debian'
      'apt'
      when 'suse', 'sles', 'opensuse-leap'
      'zypper'
    end
  end

  action('lsb_release') do |attrs, bin='lsb_release'|
    if /distributor\s+id:\s+(.*)/i =~ run("#{bin} -i").chomp
      attrs[:os_distro] = case distro = $1
        when /RedHat/i
        'rhel'
        when /SUSE/i
        run("#{bin} -d").chomp =~ /opensuse/i ? 'suse' : 'sles'
        else
        distro.downcase
      end
      if /release:\s+(.*)/i =~ run("#{bin} -r").chomp
        attrs[:os_version] = $1
      end
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
    attrs[:os_distro] = vars['ID'].downcase
    attrs[:os_version] = vars['VERSION_ID']
    if attrs[:os_distro] == 'centos' && remote('/etc/centos-release').exists?
      data = remote('/etc/centos-release').content.split("\n").collect {|l| l.strip }
      data.each do |line|
        if line =~ /\s+release\s+(\d+)\.(\d+).*/
          attrs[:os_version] = "#{$1}.#{$2}"
        end
      end
    end
  end

  action('redhat-release') do |attrs|
    data = remote('/etc/redhat-release').content.split("\n").collect {|l| l.strip }
    data.each do |line|
      if line =~ /\A(.+)\s+release\s+(\d+)(\.(\d+))?/
        attrs[:os_version] = "#{$2}.#{$4 || '0'}"
        tmpos = $1.strip.downcase
        attrs[:os_distro] = case tmpos
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
    attrs[:os_distro] = data.shift.split(' ').first.downcase
    data.each do |l|
      if data =~ /\AVERSION\s*=\s*(.*)/i
        attrs[:os_version] = $1.strip
      end
    end
  end

  action('debian-version') do |attrs|
    attrs[:os_distro] = 'debian'
    attrs[:os_version] = remote('/etc/debian-version').content.strip
  end

  # :nocov:

end
