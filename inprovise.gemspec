require_relative './lib/inprovise/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Martin Corino"]
  gem.email         = ["mcorino@remedy.nl"]
  gem.description   = %q{InProvisE is Intuitive Provisioning Environment}
  gem.summary       = %q{Simple, easy and intuitive infrastructure provisioning}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "inprovise"
  gem.require_paths = ["lib"]
  gem.version       = Inprovise::VERSION
  gem.add_dependency('colored')
  gem.add_dependency('net-ssh')
  gem.add_dependency('net-sftp')
  gem.add_dependency('gli')
  gem.add_dependency('tilt')
  gem.post_install_message = ''
end
