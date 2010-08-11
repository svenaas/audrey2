require 'helper'

class TestOptions < Test::Unit::TestCase
  context 'Calling Options::parse' do

    context 'without a configfile location specified' do
      setup do
        @options = Audrey2::Options.parse([])
      end
      
      should 'use the default configfile location' do
        assert_equal '/etc/audrey2.conf', @options[:config]
      end
    end

    context 'with a configfile location specified' do
      setup do
        @options = Audrey2::Options.parse(['--config', 'my_config_file'])
      end
      
      should 'use the specified configfile location' do
        assert_equal 'my_config_file', @options[:config]
      end
    end

    context 'with various options and recipes' do
      setup do
        @args = ['--config', 'my_config_file', 'recipe1', 'recipe2']
        Audrey2::Options.parse(@args)
      end
      
      should 'consume the options and leave the recipe list' do
        assert_equal 2, @args.length
        assert_equal 'recipe1', @args[0]
        assert_equal 'recipe2', @args[1]
      end
    end

    context 'with an invalid option' do
      setup { @args = ['--invalid'] }
      
      should 'report error, print usage, and exit' do
        Audrey2::Options.expects(:exit).with(1)
        err = capture_stderr { Audrey2::Options.parse(@args) }
        assert err.string =~ /invalid option: --invalid/
        assert err.string =~ /Usage:/
      end
    end
    
    context 'with a missing option argument' do
      setup { @args = ['--config'] }
      
      should 'report error, print usage, and exit' do
        Audrey2::Options.expects(:exit).with(1)
        err = capture_stderr { Audrey2::Options.parse(@args) }
        assert err.string =~ /missing argument: --config/
        assert err.string =~ /Usage:/
      end
    end
    
    context 'with --help' do
      setup { @args = ['--help']}

      should 'print usage and exit' do
        Audrey2::Options.expects(:exit).with()
        out = capture_stdout { Audrey2::Options.parse(@args) }
        assert out.string =~ /Usage:/
      end
    end
  end
    
end
