# Windows Cygwin Command helper for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

Inprovise::CmdHelper.define('cygwin', Inprovise::CmdHelper.implementations['linux']) do

  def initialize(channel)
    super(channel)
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
    return self
  end

  # basic commands

end
