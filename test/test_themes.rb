require 'helper'

class TestThemes < Test::Unit::TestCase
  context "With an initialized Aggregator and a valid recipe" do
    setup do
      @config
      File.stubs(:exist?).with('configfile').returns(true)
      File.stubs(:readable?).with('configfile').returns(true)
      YAML.stubs(:load_file).with('configfile').returns({
        'recipes_folder' => 'recipes_folder',
        'themes_folder'  => 'themes_folder',
        'user_agent'     => 'user_agent',
        'sort'           => 'sort'
      })
      File.stubs(:exist?).with('recipes_folder').returns(true)
      File.stubs(:readable?).with('recipes_folder').returns(true)
      File.stubs(:exist?).with('themes_folder').returns(true)
      File.stubs(:readable?).with('themes_folder').returns(true)
      @aggregator = Audrey2::Aggregator.new('configfile')
      recipefile = File.join('recipes_folder', 'recipe')
      outputfile = File.join('output_folder', 'output_file')
      File.stubs(:exist?).with(recipefile).returns(true)
      File.stubs(:readable?).with(recipefile).returns(true)
      YAML.stubs(:load_file).with(recipefile).returns({
        'feeds'       => [{ 'name' => 'feed', 'url'  => 'http://test.com/feed.xml' }],
        'theme'       => 'theme',
        'output_file' =>  outputfile
      })
      File.stubs(:exist?).with('output_folder').returns(true)
      File.stubs(:writable?).with('output_folder').returns(true)
      File.stubs(:exist?).with(outputfile).returns(false)
    end

    context "and a nonexistent theme folder" do
      should 'report error and exit' do
        theme_path = File.join('themes_folder', 'theme')
        File.expects(:exist?).with(theme_path).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Theme #{theme_path} does not exist/, err.string
      end
    end

    context "and an unreadable theme folder" do
      should 'report error and exit' do
        theme_path = File.join('themes_folder', 'theme')
        File.stubs(:exist?).with(theme_path).returns(true)
        File.expects(:readable?).with(theme_path).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Theme #{theme_path} is not readable/, err.string
      end
    end

    context "and a valid theme folder" do
      setup do
        @theme_path = File.join('themes_folder', 'theme')
        File.stubs(:exist?).with(@theme_path).returns(true)
        File.stubs(:readable?).with(@theme_path).returns(true)
        @entry_template_path = File.join(@theme_path, 'entry.haml')
      end

      context "and a nonexistent entry template file" do
        should 'report error and exit' do
          File.expects(:exist?).with(@entry_template_path).returns(false)
          err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
          assert_match /ERROR: Theme theme does not include an entry template \(entry\.haml\)/, err.string
        end
      end

      context "and an unreadable entry template file" do
        should 'report error and exit' do
          File.stubs(:exist?).with(@entry_template_path).returns(true)
          File.expects(:readable?).with(@entry_template_path).returns(false)
          err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
          assert_match /ERROR: Entry template #{@entry_template_path} is not readable/, err.string
        end
      end

      context "and an entry template file" do
        setup do
          File.stubs(:exist?).with(@entry_template_path).returns(true)
          File.stubs(:readable?).with(@entry_template_path).returns(true)
          @helpers_file_path = File.join(@theme_path, 'helpers.rb')
        end

        # Note: A stab at the following is being taken in test_parse.rb, but I'm really
        # not sure it belongs there. The challenge is to test things like this which 
        # happen when everything is proceeding as it should, but without needing to test
        # events which occur later (like the actual parsing, aggregation, and output).
        # should "load the entry template" do
        #   File.expects(:read).with(@entry_template_path).returns('Template code')
        #   assert_equal 'Template code', @aggregator.instance_variable_get('@entry_template')
        # end

        context "and an unreadable helpers file" do
          setup do
            File.stubs(:read).with(@entry_template_path).returns('Template code')
          end

          should 'report error and exit' do
            File.expects(:exist?).with(@helpers_file_path).returns(true)
            File.expects(:readable?).with(@helpers_file_path).returns(false)
            err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
            assert_match /ERROR: Helpers file #{@helpers_file_path} is not readable/, err.string
          end
        end
      end

    end
  end
end