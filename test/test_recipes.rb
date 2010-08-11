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
        File.expects(:readable?).with(recipefile).returns(true)
        YAML.expects(:load_file).with(recipefile).raises(Exception)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Problem parsing recipe file #{recipefile}/, err.string
      end
    end

  end
end