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

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
  
end

class TestOptions < Test::Unit::TestCase
  context 'Options::parse' do
    should 'report error, print usage, and exit when called with invalid option' do
      Audrey2::Options.expects(:exit).with(1)
      err = capture_stderr { Audrey2::Options.parse(['--invalid']) }
      assert err.string =~ /invalid option: --invalid/
      assert err.string =~ /Usage:/
    end

    should 'report error, print usage, and exit when called with missing option argument' do
      Audrey2::Options.expects(:exit).with(1)
      err = capture_stderr { Audrey2::Options.parse(['--config']) }
      assert err.string =~ /missing argument: --config/
      assert err.string =~ /Usage:/
    end

    should 'report print usage and exit when called with --help' do
      Audrey2::Options.expects(:exit).with()
      out = capture_stdout { Audrey2::Options.parse(['--help']) }
      assert out.string =~ /Usage:/
    end
  end
    
end
