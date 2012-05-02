# -*- encoding: utf-8 -*-
require File.expand_path('../lib/hydra-ldap/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Coyne"]
  gem.email         = ["justin.coyne@yourmediashelf.com"]
  gem.description   = %q{A gem for managing groups with ldap}
  gem.summary       = %q{Create, Read and Update LDAP groups}
  gem.homepage      = "https://github.com/projecthydra/hydra-ldap"

  gem.add_dependency('rails')
  gem.add_dependency('net-ldap')
  

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "hydra-ldap"
  gem.require_paths = ["lib"]
  gem.version       = Hydra::LDAP::VERSION
end
