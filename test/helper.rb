require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'bin'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'audrey2'

# The following trick is via http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/
require 'stringio'
module Kernel
  def capture_stderr
    err = StringIO.new
    $stderr = err
    yield
    return err
  ensure
    $stderr = STDERR
  end

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
end

class Test::Unit::TestCase
end
