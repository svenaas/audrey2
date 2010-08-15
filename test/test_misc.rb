require 'helper'

class TestMisc < Test::Unit::TestCase
  context "With HashExtensions loaded, Hash " do
    setup do
      @hash = {
        'key1' => 'value1',
        'key2' => :value2,
        :key3  => 'value3',
        :key4  => :value4,
        'key5' => { 'key5.1' => 'value5.1', 'key5.2' => {'key5.2.1' => 'value5.2.1'}},
        'key6' => [ {'key6.1' => 'value6.1'}, {'key6.2' => 'value6.2'}]
      }
    end
    
    should "mixin HashExtensions" do
      assert Hash.ancestors.include? HashExtensions
    end
    
    
    should "respond to recursively_symbolize_keys" do
      assert @hash.respond_to? :recursively_symbolize_keys
    end

    context "output by Hash#recursively_symbolize_keys" do
      setup do
        @symbolized_hash = @hash.recursively_symbolize_keys
      end
        
      should 'convert string keys to symbols' do
        [:key1, :key2, :key5, :key6].each { |key| assert @symbolized_hash.has_key? key }
      end
    
      should 'leave symbol keys untouched' do
        [:key3, :key4].each { |key| assert @symbolized_hash.has_key? key }
      end
    
      should 'recurse into child hashes' do
        [:'key5.1', :'key5.2'].each { |key| assert @symbolized_hash[:key5].has_key? key }
        assert @symbolized_hash[:key5].has_key? :'key5.2'
        assert @symbolized_hash[:key5][:'key5.2'].has_key? :'key5.2.1'
      end
    
      should 'recurse into child arrays which contain hashes' do
        [:'key6.1', :'key6.2'].each_with_index { |key, i| assert @symbolized_hash[:key6][i].has_key? key }      
      end
    end
    
  end
end
