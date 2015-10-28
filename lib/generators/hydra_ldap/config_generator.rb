require 'rails/generators'

module HydraLdap
  class ConfigGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def create_config_file
      copy_file 'hydra-ldap.yml', 'config/hydra-ldap.yml'
    end
  end
end