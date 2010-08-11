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

    context "with a readable configfile" do
      setup do 
        File.stubs(:exist?).with('configfile').returns(true)
        File.stubs(:readable?).with('configfile').returns(true)
        YAML.stubs(:load_file).with('configfile').returns({'recipes_folder' => 'recipes_folder'})
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
    end

  end
end
