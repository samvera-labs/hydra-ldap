$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec/autorun'
require 'hydra-ldap'
require 'ladle'

RSpec.configure do |config|

end

