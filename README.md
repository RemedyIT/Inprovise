
Inprovise
=========

**Because provisioning small computing infrastructures should be simple, intuitive and NOT require additional infrastructure or elaborate setups just to run your provisioning scripts.**

Inprovise (Intuitive Provisioning Environment) is a super simple way to provision servers and virtual machines.

[![Build Status](https://travis-ci.org/mcorino/Inprovise.png)](https://travis-ci.org/mcorino/Inprovise)
[![Code Climate](https://codeclimate.com/github/RemedyIT/Inprovise/badges/gpa.png)](https://codeclimate.com/github/RemedyIT/Inprovise)
[![Test Coverage](https://codeclimate.com/github/RemedyIT/Inprovise/badges/coverage.png)](https://codeclimate.com/github/RemedyIT/Inprovise/coverage)
[![Gem Version](https://badge.fury.io/rb/inprovise.png)](https://badge.fury.io/rb/inprovise)

If you've found yourself stuck in the gap between deployment tools like Capistrano and full blown infrastructure tools like Puppet and Chef then Inprovise might be a good fit for you.
This is especially the case if you choose to cycle machines and prefer baking from scratch when changes are required rather than attempting to converge system state
(although Inprovise is flexible and extensible enough to achieve anything you would like).

Acknowledgement
---------------

First off a very big acknowledgment.
When searching (yet again) for a usable (as in 'easy' and 'intuitive') tool for managing the provisioning of our smallish computing farm
(consisting of <10 host servers each running 6-12 VMs each) and yet again becoming disappointed by the requirements and overkill offered by tools like
Chef and Puppet, I finally found the *Orca* tool by Andy Kent (https://github.com/andykent/orca).
*This* was what I was thinking of!

Unfortunately Andy some time ago deprecated his project and there were some aspects of Orca I did not really like (a major one being the definition of the infrastructure nodes and groups inside the provisioning schemes)
as well as some missing bits (like more flexibility in the platform support).
I really did like the agent-less setup and the simple and elegant structure of the DSL though as well as the fact it was written in one of my favorite programming languages. As Andy's arguments for discontinuing
did not apply to us I decided to take up his code and rework it to my ideas and provide it with a minimum of multi platform support to also be able to manage the non-*nix nodes we needed to provision.

As Andy indicated the Orca name was (to be) handed over to another gem maintainer and I did not particularly like it anyway (sorry Andy) I renamed the package. Andy's code proved quite resilient to my changes
though and (apart from the name changes) I was able to copy large chunks more or less verbatim and rework those step by step thereby increasing my coding production significantly.

What problem does Inprovise try to solve?
------------------------------------

All too often you need to get a new server up and running to a known state so that you can get an app deployed. Before Inprovise (and Orca) there were broadly 4 options...

1. Start from scratch and hand install all the packages, files, permissions, etc. yourself over SSH.
2. Use a deployment tool like Capistrano to codeify your shell scripts into semi-reusable steps.
3. Use Puppet or Chef in single machine mode, requiring to install these tools on each host server.
4. Use Full blown Puppet or Chef, this requires a server.

Inprovise fills the rather large gap between (2) and (3). It's a bigger gap then you think as both Puppet and Chef require...

- bootstrapping a machine to a point where you are able to run them
- Creating a separate repository describing the configuration you require
- learning their complex syntaxes and structures
- hiding the differences of different host OSes

Inprovise fixes these problems by...

- working directly over standardized protocols (SSH by default), all you need is a box that you can connect to
- Inprovise maintains a simple (JSON) file based registry of your infrastructure
- scripting definitions can all go in a single file (although Inprovise supports modularization) and most servers can be configured in ~50 lines
- scripts are defined in a ruby based DSL that consists of a very small number of basic commands to learn
- Inprovise only requires a minimum operations (for cmd execution and file management) to be supported for any OS the details of which are abstracted through configurable handlers
- apart from the protocol and minimal operation set Inprovise makes no assumptions about the underlying OS
- Inprovise is extensible and adding platform specific features like package manager support can be achieved in a small amount of code using the core support


What problems is Inprovise avoiding?
-------------------------------

Inprovise intentionally skirts around some important things that may or may not matter to you.
If they do then you are probably better using tools such as Puppet or Chef.

Inprovise doesn't...

- try to scale beyond a smallish (2-100) number of nodes
- have any algorithms that attempt to run periodically and converge divergent configurations
- fully abstract the differences of different host OSes (in particular specific system support options and package management)
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

If you have a script with the same name as a group or node you can abbreviate this to...

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

````ruby
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
````

Configuration
-------------

The `rig` CLI tool loads a file named 'rigrc' at startup if available in the root of your project (where the 'infra.json' is located). This file is assumed
to contain pure Ruby code and is loaded as such. You can use this to require and setup any libraries, extensions etc. you want to be available to your
scripts defined in your project's scheme files.

As the scheme files themselves are also pure Ruby code you can also put configuration code there if that suites your use case better (for example if certain settings
should only be available to scripts defined in one particular scheme file).

Extensions
----------

The core of Inprovise only provides a minimum of platform specific logic but is designed to be a foundation to build apon.
Basically the core currently supports using the SSH(+SFTP) protocol and provides operation handlers for `linux` and `cygwin` type OS environments.

Extensions can be written in their own files, projects or gems and loaded through the `rigrc` config file or any of your project's scheme files.
As these files are all pure Ruby code you can use 'require' statements and/or any other valid Ruby code to initialize your extensions.

