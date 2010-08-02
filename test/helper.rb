require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'bin'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'audrey2'

class Test::Unit::TestCase
end
