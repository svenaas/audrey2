require 'helper'

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
end

class TestFeedme < Test::Unit::TestCase
  FEEDME_BINARY = File.join(File.dirname(__FILE__), '../bin/feedme')
  
  context 'The feedme command-line script' do

    should 'print usage and exit when called without arguments' do
      Object.any_instance.expects(:exit).with(1)
      err = capture_stderr { load FEEDME_BINARY }
      assert err.string =~ /You must specify at least one recipe to feed me/
      assert err.string =~ /Usage:/
    end

  end
    
end
