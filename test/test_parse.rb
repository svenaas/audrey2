require 'helper'

class TestParse < Test::Unit::TestCase
  context "With an initialized Aggregator and all configuration met (no email)" do
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
      @feed = { 'name' => 'feed', 'url'  => 'http://test.com/feed.xml' }
      YAML.stubs(:load_file).with(recipefile).returns({
        'feeds'       => [@feed],
        'theme'       => 'theme',
        'output_file' =>  outputfile
      })
      File.stubs(:exist?).with('output_folder').returns(true)
      File.stubs(:writable?).with('output_folder').returns(true)
      File.stubs(:exist?).with(outputfile).returns(false)
      theme_path = File.join('themes_folder', 'theme')
      File.stubs(:exist?).with(theme_path).returns(true)
      File.stubs(:readable?).with(theme_path).returns(true)     
      entry_template_path = File.join(theme_path, 'entry.haml')
      File.stubs(:exist?).with(entry_template_path).returns(true)
      File.stubs(:readable?).with(entry_template_path).returns(true)   
      File.stubs(:read).with(entry_template_path).returns('%p= entry.title')
      helpers_file_path = File.join(theme_path, 'helpers.rb')      
      File.stubs(:exist?).with(helpers_file_path).returns(false)      
      @feed_content =<<-EOF
<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Test</title>
    <link>http://test.com/</link>
    <description>Test channel</description>
    <item>
       <title>Title</title>
       <link>http://test.com/title</link>
       <description>Test description</description>
       <pubDate>Sun, 15 Aug 2010 16:46:00 EDT</pubDate>
    </item>
  </channel>
</rss>
EOF
    end

    should 'download, parse, and write templatized output' do
      @aggregator.expects(:open).with('http://test.com/feed.xml', {'User-Agent' => 'user_agent'}).returns(@feed_content)
      s = StringIO.new
      s.expects(:<<).with("<p>Title</p>\n")
      File.expects(:open).with(File.join('output_folder', 'output_file'), 'w').yields s
      @aggregator.feed_me('recipe')
      assert_equal '%p= entry.title', @aggregator.instance_variable_get('@entry_template')
    end
    
    should 'report feed-opening error via exit' do 
      @aggregator.expects(:open).with('http://test.com/feed.xml', {'User-Agent' => 'user_agent'}).raises(Exception.new('404 Not Found'))
      err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
      assert err.string =~ /An exception occurred while running recipe recipe:/
      assert err.string =~ /Exception occurred when opening feed feed at http:\/\/test.com\/feed.xml:/
      assert err.string =~ /404 Not Found/
    end

    should 'report feed-parsing error via exit' do 
      @aggregator.stubs(:open).with('http://test.com/feed.xml', {'User-Agent' => 'user_agent'}).returns(@feed_content)
      FeedNormalizer::FeedNormalizer.expects(:parse).with(@feed_content).raises(Exception.new("Parsing exception"))
      err = capture_stderr { assert_raise(SystemExit) { @aggregator.feed_me('recipe') } }
      assert err.string =~ /An exception occurred while running recipe recipe:/
      assert err.string =~ /Exception occurred when parsing feed feed which was downloaded from http:\/\/test.com\/feed.xml:/
      assert err.string =~ /Parsing exception/
    end

  end
end