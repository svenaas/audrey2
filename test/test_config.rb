require 'helper'

class TestConfig < Test::Unit::TestCase
  context "Initializing an Aggregator" do

    context "without a configfile" do
      should 'report error and exit' do
        File.stubs(:exist?).with('configfile').returns(false)
        err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
        assert_match /ERROR: Configuration file configfile does not exist/, err.string
      end
    end

    context "with an unreadable configfile" do
      should 'report error and exit' do
        File.stubs(:exist?).with('configfile').returns(true)
        File.expects(:readable?).with('configfile').returns(false)
        err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
        assert_match /ERROR: Configuration file configfile is not readable/, err.string
      end
    end

    context "with an unparsable configfile" do
      should 'report error and exit' do
        File.stubs(:exist?).with('configfile').returns(true)
        File.stubs(:readable?).with('configfile').returns(true)
        YAML.expects(:load_file).with('configfile').raises(Exception)
        err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
        assert_match /ERROR: Problem parsing configuration file configfile/, err.string
      end
    end

    context "with a valid configfile" do
      setup do
        @config
        File.stubs(:exist?).with('configfile').returns(true)
        File.stubs(:readable?).with('configfile').returns(true)
        YAML.stubs(:load_file).with('configfile').returns({
          'recipes_folder' => 'recipes_folder',
          'themes_folder'  => 'themes_folder'
        })
      end

      context "without a recipes folder" do
        should 'report error and exit' do
          File.expects(:exist?).with('recipes_folder').returns(false)
          err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
          assert err.string =~ /ERROR: Recipes folder recipes_folder does not exist/
        end
      end

      context "with an unreadable recipes folder" do
        should 'report error and exit' do
          File.stubs(:exist?).with('recipes_folder').returns(true)
          File.expects(:readable?).with('recipes_folder').returns(false)
          err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
          assert err.string =~ /ERROR: Recipes folder recipes_folder is not readable/
        end
      end

      context "and recipes folder" do
        setup do
          File.stubs(:exist?).with('recipes_folder').returns(true)
          File.stubs(:readable?).with('recipes_folder').returns(true)
        end

        context "without a themes folder" do
          should 'report error and exit' do
            File.expects(:exist?).with('themes_folder').returns(false)
            err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
            assert err.string =~ /ERROR: Themes folder themes_folder does not exist/
          end
        end

        context "with an unreadable themes folder" do
          should 'report error and exit' do
            File.stubs(:exist?).with('themes_folder').returns(true)
            File.expects(:readable?).with('themes_folder').returns(false)
            err = capture_stderr { assert_raise(SystemExit) { Audrey2::Aggregator.new('configfile') } }
            assert err.string =~ /ERROR: Themes folder themes_folder is not readable/
          end
        end

        context "and themes folder" do
          setup do
            File.stubs(:exist?).with('themes_folder').returns(true)
            File.stubs(:readable?).with('themes_folder').returns(true)
            @aggregator = Audrey2::Aggregator.new('configfile')
          end

          should "return a valid aggregator" do
            assert_not_nil @aggregator
          end

          should "use the default user agent" do
            assert_equal 'Audrey 2.0 Feed Aggregator', @aggregator.instance_variable_get('@user_agent')
          end

          should "use the default sort" do
            assert_equal 'reverse-chronological', @aggregator.instance_variable_get('@sort')
          end

          should "not setup email" do
            assert_nil @aggregator.instance_variable_get('@email')
          end
        end
      end
    end

  end
end
