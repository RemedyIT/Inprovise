
Inprovise
=========

**Because provisioning small computing infrastructures should be simple, intuitive and NOT require additional infrastructure or elaborate setups just to run your provisioning scripts.** 

Inprovise (Intuitive Provisioning Environment) is a super simple way to provision servers and virtual machines.

If you've found yourself stuck in the gap between deployment tools like Capistrano and full blown infrastructure tools like Puppet and Chef then Inprovise is probably for you. 
This is especially the case if you choose to cycle machines and prefer baking from scratch when changes are required rather than attempting to converge system state (although Inprovise is flexible and extensible enough to achieve anything you would like).

Acknowledgement
---------------

First off a very big acknowledgement.
When searching (yet again) for a usable (as in 'easy' and 'intuitive') tool for managing the provisioning of our smallish computing farm 
(consisting of <10 host servers each running 6-12 VMs each) and yet again becoming disappointed by the requirements and overkill offered by tools like
Chef and Puppet, I finally found the *Orca* tool by Andy Kent (https://github.com/andykent/orca).
*This* was what I was thinking of!

Unfortunately Andy some time ago deprecated his project and there were some aspects of Orca I did not really like (a major one being the definition of the infrastructure nodes and groups inside the provisioning schemes).
I really did like the agent-less setup and the simple and elegant structure of the DSL though as well as the fact it was written in one of my favorite programming languages and as Andy's arguments for discontinuing 
did not apply to us I decided to take up his code and rework it to my ideas.

As Andy indicated the Orca name was (to be) handed over to another gem maintainer and I did not particularly like it anyway (sorry Andy) I renamed the package. Andy's code proved quite resilient to my changes
though and (apart from the name changes) I was able to copy large chunks more or less verbatim thereby increasing my coding production significantly.
    

What problem does Inprovise try to solve?
------------------------------------

All too often you need to get a new server up and running to a known state so that you can get an app deployed. Before Inprovise there were broadly 4 options...

1. Start from scratch and hand install all the packages, files, permissions, etc. yourself over SSH.
2. Use a deployment tool like Capistrano to codeify your shell scripts into semi-reusable steps.
3. Use Puppet or Chef in single machine mode, requiring to install these tools on each host server.
4. Use Full blown Puppet or Chef, this requires a server.

Inprovise fills the rather large gap between (2) and (3). It's a bigger gap then you think as both Puppet and Chef require...

- bootstrapping a machine to a point where you are able to run them
- Creating a seperate repository describing the configuration you require
- learning their complex syntaxes and structures
- hiding the differences of different host OSes

Inprovise fixes these problems by...

- working directly over SSH, all you need is a box that you can connect to
- Inprovise maintains a simple (JSON) file based registry of your infrastructure  
- scripting definitions can all go in a single file (although Inprovise supports modularization) and most servers can be configured in ~50 lines
- scripts are defined in a ruby based DSL that consists of a very small number of basic commands to learn
- Inprovise makes no assumptions about the underlying OS except to assume it supports SSH
- Inprovise is extensible and adding platform specific features like package manger support can be achieved in a dozen or so lines.


What problems is Inprovise avoiding?
-------------------------------

Inprovise intentionally skirts around some important things that may or may not matter to you. 
If they do then you are probably better using tools such as Puppet or Chef.

Inprovise doesn't...

- try to scale beyond a smallish (2-100) number of nodes
- have any algorithms that attempt to run periodically and converge divergent configurations
- abstract the differences of different host OSes
- provide a server to supervise infrastructure configuration


Installation
------------

To install Inprovise you will need to be running Ruby 2+ and then install the inprovise gem...

    gem install inprovise

or ideally add it to your gemfile...

    gem 'inprovise'


Command Line Usage
------------------

Inprovise provides a CLI tool called `rig`

To get started from within your project you can run...

    rig init

This will create an empty infra.json and an example inprovise.rb file for you to get started with.

To manage nodes you can run...

    rig node [add|remove|update] [options] [arguments]

To manage groups you can run...

    rig group [add|remove|update] [options] [arguments]

To run a command the syntax is as follows...

    rig [command] [script] [group_or_node]

So here are some examples (assuming you have a script called "app" and a node called "server" defined)...

    rig apply app server
    rig revert app server
    rig validate app server

If you have a script with the same name as a group or node you can abreviate this to...

    rig apply server
    rig remove server
    rig validate server

You can also directly trigger actions from the CLI like so...

    rig trigger nginx:reload web-1
    rig trigger firewall:add[allow,80] web-1

Options, all commands support the following optional parameters...

    --demonstrate       | dont actually run any commands just pretend like you are
    --sequential        | dont attempt to run commands across multiple nodes in parrallel
    --verbose=LEVEL     | increase logging level to see exceptions printed as well as SSH commands and results
    --skip-dependencies | Don't validate and run dependancies, only the script specified

The `help` command shows basic or command specific help info if you run...

    rig help [command]

The Inprovise DSL
------------

Inprovise provides a Ruby based DSL to write your provisioning specifications. Files containing these provisioning
specs are called `schemes`.
Inprovise provisioning schemes are pure Ruby code and should preferably be stored in files with the '.rb' extension. When
no scheme is specified Inprovise looks for the scheme `inprovise.rb` in the projects root (where the `infa.json` is located) by default. 
Scheme scripts are really simple to learn in less than 5 mins. Below is an example inprovise.rb file with some hints to help you get started. 
A more complete WIP example can be found in this gist... https://gist.github.com/andykent/5814997

    # define a new script called 'gem' that provides some actions for managing rubygems
    script 'gem' do
      depends_on 'ruby-1.9.3'                     # this script depends on another script called ruby-1.9.3
      action 'exists' do |gem_name|               # define an action that other scripts can trigger called 'exists'
        run("gem list -i #{gem_name}") =~ /true/  # execute the command, get the output and check it contains 'true'
      end
      action 'install' do |gem_name|
        run "gem install #{gem_name} --no-ri --no-rdoc"
      end
      action 'uninstall' do |gem_name|
        run "gem uninstall #{gem_name} -x -a"
      end
    end

    # define a script called 'bundler' that can be used to manage the gem by the same name
    script 'bundler' do
      depends_on 'gem'
      apply do                                # apply gets called whenever this script or a script that depends on it is applied
        trigger('gem:install', 'bundler')     # trigger triggers defined actions, in this case the action 'install' on 'gem'
      end
      remove do                               # remove gets called whenever this script or a script that depends on it is removed
        trigger('gem:uninstall', 'bundler')
      end
      validate do                             # validate is used internally to check if the script is applied correctly or not
        trigger('gem:exists', 'bundler')      # validate should return true if the script is applied correctly
      end
    end



Extensions
----------

The core of Inprovise doesn't have any platform specific logic but is designed to be a foundation to build apon. 
Extensions can be written in their own files, projects or gems, simply `require 'orca'` and then use the `Inprovise.extension` helper.

Some example extensions are included in this repo and can be required into your orca.rb file if you need them...

`require "orca/extensions/apt"` - Adds support for specifying aptitude dependancies with the `apt_package` helper.

`relative "orca/extensions/file_sync"` - Adds support for syncing and converging local/remove files with the `file` action.

*Note: these extensions are likely to be removed to their own 'contrib' project at some point in the future*

