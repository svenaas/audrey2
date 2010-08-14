require 'helper'

class TestOptions < Test::Unit::TestCase
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
    
    context "And an unordered set of entries" do
      setup do 
        class TestEntry
          attr_accessor :date_published
          def initialize(date_published); @date_published = date_published; end
        end
        @entry1 = TestEntry.new(Date.parse('2010-08-08'))
        @entry2 = TestEntry.new(Date.parse('2010-08-09'))
        @entry3 = TestEntry.new(Date.parse('2010-08-10'))
        @entries = [@entry3, @entry1, @entry2]
      end
      
      should "sort in reverse order under reverse_chronological sort" do
        assert_equal @entry3, @entries[0]
        assert_equal @entry1, @entries[1]
        assert_equal @entry2, @entries[2]
        @entries.sort! &@aggregator.send(:entry_sort_comparator, 'reverse_chronological')
        assert_equal @entry3, @entries[0]
        assert_equal @entry2, @entries[1]
        assert_equal @entry1, @entries[2]        
      end

      should "sort in chronological order under chronological sort" do
        assert_equal @entry3, @entries[0]
        assert_equal @entry1, @entries[1]
        assert_equal @entry2, @entries[2]
        @entries.sort! &@aggregator.send(:entry_sort_comparator, 'chronological')
        assert_equal @entry1, @entries[0]
        assert_equal @entry2, @entries[1]
        assert_equal @entry3, @entries[2]        
      end
      
    end
  end
end
