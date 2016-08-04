# Platform sniffer for Inprovise
#
# Author::    Martin Corino
# Copyright:: Copyright (c) 2016 Martin Corino
# License::   Distributes under the same license as Ruby

class Inprovise::Sniffer::PlatformSniffer
  include Inprovise::Sniffer::SnifferMixin

  def run
    attrs = {}
    attrs['machine'] = context.run('uname -m').strip
    ostype = context.run('uname -o').strip
    attrs['os'] = '(unknown)'
    case ostype
    when /linux/i
      get_linux_platform(attrs)
    end
    attrs
  end

  private

  def get_linux_platform(attrs)
    if context.remote('/etc/os-release').exists?
      get_os_release(attrs)
    elsif context.remote('/etc/redhat-release').exists?
      get_redhat_release(attrs)
    elsif context.remote('/etc/SuSE-release').exists?
      get_suse_release(attrs)
    end
    attrs['pkgman'] = case attrs['os']
                      when 'fedora', 'centos', 'rhel'
                        chk = context.run('which dnf').strip
                        chk.empty? ? 'yum' : 'dnf'
                      when /suse/
                        'zypper'
                      end
  end

  def get_os_release(attrs)
    data = context.remote('/etc/os-release').cat.split("\n").collect {|l| l.strip }
    vars = data.inject({}) do |hash, line|
      unless line.empty? || line.start_with?('#') || !(line =~ /[^=]+=.*/)
        var, val = line.split('=')
        hash[var] = val.strip.gsub(/(\A")|("\Z)/, '')
      end
      hash
    end
    attrs['os'] = vars['ID'].downcase
    attrs['os-version'] = vars['VERSION_ID']
    if attrs['os'] == 'centos' && context.remote('/etc/centos-release').exists?
      data = context.remote('/etc/centos-release').cat.split("\n").collect {|l| l.strip }
      data.each do |line|
        if line =~ /\s+release\s+(\d+)\.(\d+).*/
          attrs['os-version'] = "#{$1}.#{$2}"
        end
      end
    end
  end

  def get_redhat_release(attrs)
    data = context.remote('/etc/redhat-release').cat.split("\n").collect {|l| l.strip }
    data.each do |line|
      if line =~ /\A(.+)\s+release\s+(\d+)(\.(\d+))?/
        attrs['os-version'] = "#{$2}.#{$4 || '0'}"
        tmpos = $1.strip.downcase
        attrs['os'] = case tmpos
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

  def get_suse_release(attrs)
    data = context.remote('/etc/SuSE-release').cat.split("\n").collect {|l| l.strip }
    attrs['os'] = data.shift.split(' ').first.downcase
    data.each do |l|
      if data =~ /\AVERSION\s*=\s*(.*)/i
        attrs['os-version'] = $1.strip
      end
    end
  end
end
