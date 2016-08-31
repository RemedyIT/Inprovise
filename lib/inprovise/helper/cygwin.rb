# Windows Cygwin Command helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::CmdHelper.define('cygwin', Inprovise::CmdHelper.implementations['linux']) do

  def initialize(channel)
    super(channel)
    # only if this is *NOT* a sudo helper
    unless channel.node.user == admin_user
      if channel.node.config.has_key?(:credentials) && channel.node.config[:credentials].has_key?(:'public-key')
        # trigger sudo channel creation to have pubkey installed for admin as well
        sudo
      end
    end
  end

  # platform properties

  def admin_user
    'administrator'
  end

  def env_reference(varname)
    "\$#{varname}"
  end

  # generic command execution

  def sudo
    return self if channel.node.user == admin_user
    unless @sudo
      @sudo = channel.node.for_user(admin_user).helper
      @sudo.cwd = self.cwd
    end
    @sudo.channel.node.log_to(channel.node.log.clone_for_node(@sudo.channel.node))
    @sudo
  end

  # basic commands

end
