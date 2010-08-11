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

    context "and a nonexistent theme file" do
      should 'report error and exit' do
        themefile = File.join('themes_folder', 'theme')
        File.expects(:exist?).with(themefile).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Theme #{themefile} does not exist/, err.string
      end
    end

    context "and an unreadable recipe file" do
      should 'report error and exit' do
        themefile = File.join('themes_folder', 'theme')
        File.stubs(:exist?).with(themefile).returns(true)
        File.expects(:readable?).with(themefile).returns(false)
        err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
        assert_match /ERROR: Theme #{themefile} is not readable/, err.string
      end
    end

  end
end