require 'helper'

class TestRecipes < Test::Unit::TestCase
  context "With an initialized Aggregator" do
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
    end

    context "and a nonexistent recipe file" do
      should 'report error and exit' do
        recipefile = File.join('recipes_folder', 'recipe')
        File.expects(:exist?).with(recipefile).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Recipe file #{recipefile} does not exist/, err.string
      end
    end

    context "and an unreadable recipe file" do
      should 'report error and exit' do
        recipefile = File.join('recipes_folder', 'recipe')
        File.stubs(:exist?).with(recipefile).returns(true)
        File.expects(:readable?).with(recipefile).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Recipe file #{recipefile} is not readable/, err.string
      end
    end

    context "with an unparsable recipe file" do
      should 'report error and exit' do
        recipefile = File.join('recipes_folder', 'recipe')
        File.stubs(:exist?).with(recipefile).returns(true)
        File.stubs(:readable?).with(recipefile).returns(true)
        YAML.expects(:load_file).with(recipefile).raises(Exception)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Problem parsing recipe file #{recipefile}/, err.string
      end
    end

    context "and a recipe file" do
      setup do
        recipefile = File.join('recipes_folder', 'recipe')
        @outputfile = File.join('output_folder', 'output_file')
        File.stubs(:exist?).with(recipefile).returns(true)
        File.stubs(:readable?).with(recipefile).returns(true)
        YAML.stubs(:load_file).with(recipefile).returns({
          'feeds'       => [{ 'name' => 'feed', 'url'  => 'http://test.com/feed.xml' }],
          'theme'       => 'theme',
          'output_file' => @outputfile
        })
      end

      context 'with an invalid output folder' do
        should 'report error and exit' do
          File.expects(:exist?).with('output_folder').returns(false)
          err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
          assert_match /ERROR: Output folder output_folder does not exist/, err.string
        end
      end

      context "and an unwritable output folder" do
        should 'report error and exit' do
          File.stubs(:exist?).with('output_folder').returns(true)
          File.expects(:writable?).with('output_folder').returns(false)
          err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
          assert_match /ERROR: Output folder output_folder is not writable/, err.string
        end
      end

      context "and an existing but unwritable output file" do
        setup do
          File.stubs(:exist?).with('output_folder').returns(true)
          File.stubs(:writable?).with('output_folder').returns(true)
        end

        should 'report error and exit' do
          File.expects(:exist?).with(@outputfile).returns(true)
          File.expects(:writable?).with(@outputfile).returns(false)
          err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
          assert_match /ERROR: Output file #{@outputfile} is not writable/, err.string
        end
      end
      
      # TODO: Verify max_entries behavior
    end
  end
end