require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'haml'
require 'optparse'

module HashExtensions # Adapted from http://gist.github.com/151324 by Avdi Grimm and Paul Berry
  def symbolize_keys
    inject({}) do |acc, (k,v)|
      key = String === k ? k.to_sym : k
      value = case v
        when Hash
          v.symbolize_keys
        when Array
          v.collect { |e| Hash === e ? e.symbolize_keys : e }
        else
          v
        end
      acc[key] = value
      acc
    end
  end
end
Hash.send(:include, HashExtensions)

module Audrey2
  class Options
    def self.parse(args)
      options = {}

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: feedme [OPTIONS] recipes"

        options[:config] = '/etc/audrey2.conf'
        opts.on( '--config CONFIGFILE', "Location of config file", "(default: /etc/audrey2.conf)" )  do |f|
          options[:config] = f
        end

        opts.on_tail( '-h', '--help', 'Display this screen' ) do
          puts opts
          exit
        end

        begin
          opts.parse! args
          options
        rescue OptionParser::ParseError => e
          warn e.message
          $stderr.puts opts
          exit 1
        end
      end

      options
    end
  end


  class Aggregator
    def initialize(configfile)
      init_config(configfile)
    end

    def feed_me(recipe_name)
      begin
        # Load recipe and theme and make sure everything is in order
        recipe = load_recipe(recipe_name)
        output_file = recipe[:output_file]
        verify_output_file(output_file)
        max_entries = recipe[:max_entries] || 1000

        # Load theme
        init_theme(recipe[:theme])

        # Download and parse the feeds
        entry_sources = {}
        feeds = recipe[:feeds].collect { |feed| parse_feed(feed, entry_sources) }

        # Aggregate and sort the entries
        entries = []
        feeds.each { |feed| entries += feed.entries }
        entries.sort! &entry_sort_comparator

        # Prepare template evaluation scope including any helper code defined in the theme
        scope = Object.new
        scope.instance_eval(@helper_code) if @helper_code

        # Output the aggregated entries
        output = ''
        engine ||= Haml::Engine.new(@entry_template)

        entries[0..max_entries - 1].each do |entry|
          output << engine.render(scope, :entry => entry, :source => entry_sources[entry])
        end

        File.open(output_file, 'w') { |f| f << output }
      rescue Exception => e
        # NOTE: This also catches SystemExit as can be raise by Kernel#exit when recipes
        # and themes are loaded and verified. Is it good to handle those events here? Perhaps ...
        if @email
          email(<<-EOF
An exception occurred while running recipe #{recipe_name}

Exception: #{e}

Backtrace:

#{e.backtrace}
EOF
          )
        else
          $stderr.puts "An exception occurred while running recipe #{recipe_name}:\n\n#{e}\n#{e.backtrace}"
          exit(1)
        end
      end
    end

  protected
    def email(e)
      return unless @email

      mail = Mail.new
      mail[:from] =    @email[:from]
      mail[:to] =      @email[:to]
      mail[:subject] = "[AUDREY 2.0] Exception Notification"
      mail[:body]    = e

      case @email[:via]
      when :sendmail
        mail.delivery_method :sendmail
      when :smtp
        raise "Missing SMTP configuration" unless @email[:smtp]
        smtp = {
          :address        => @email[:smtp][:server]         || 'localhost',
          :port           => @email[:smtp][:port]           || 25
        }
        smtp[:domain]         = @email[:smtp][:domain]         if @email[:smtp][:domain]
        smtp[:user_name]      = @email[:smtp][:user_name]      if @email[:smtp][:user_name]
        smtp[:password]       = @email[:smtp][:password]       if @email[:smtp][:password]
        smtp[:authentication] = @email[:smtp][:authentication] if @email[:smtp][:authentication]
        mail.delivery_method :smtp, smtp
      end

      mail.deliver
    end

    def verify_output_file(output_file)
      output_folder = File.dirname(output_file)
      if ! File.exist? output_folder
        raise "ERROR: Output folder #{output_folder} does not exist."
      elsif ! File.writable? output_folder
        raise "ERROR: Output folder #{output_folder} is not writable"
      end
      if File.exist?(output_file)
        if ! File.writable? output_file
          raise "ERROR: Output file #{output_file} is not writable"
        end
      end
    end

    def init_theme(theme)
      theme_path = File.join(@themes_folder, theme)
      if ! File.exist? theme_path
        $stderr.puts "ERROR: Theme #{theme_path} does not exist."
        exit(1)
      elsif ! File.readable? theme_path
        $stderr.puts "ERROR: Theme #{theme_path} is not readable"
        exit(1)
      end

      entry_template_file = File.join(@themes_folder, theme, 'entry.haml')
      if ! File.exist? entry_template_file
        $stderr.puts "ERROR: Theme #{theme} does not include an entry template (entry.haml)"
        exit(1)
      elsif ! File.readable? entry_template_file
        $stderr.puts "ERROR: Entry template #{entry_template_file} is not readable"
        exit(1)
      end
      @entry_template = File.read(entry_template_file)

      helper_file = File.join(@themes_folder, theme, 'helpers.rb')
      @helper_code = nil
      if File.exist? helper_file
        if ! File.readable? helper_file
          $stderr.puts "ERROR: Helpers file #{helper_file} is not readable"
          exit(1)
        end
        @helper_code = File.open(helper_file) { |f| f.read }
      end
    end

    # Implements sort orders which may be specified in configuration    
    def entry_sort_comparator(sort = @sort) # Defaults to the sort order specified in configuration
      case sort
      when :reverse_chronological
        Proc.new {|a, b| b.date_published <=> a.date_published } 
      when :chronological
        Proc.new {|a, b| a.date_published <=> b.date_published } 
      end
    end

    def parse_feed(feed, entry_sources)
      remote_feed = nil
      begin
        remote_feed = open(feed[:url], "User-Agent" => @user_agent)
      rescue Exception => e
        raise "Exception occurred when opening feed #{feed[:name]} at #{feed[:url]}:\n\n" + e.to_s
      end

      parsed_feed = nil
      begin :test
        parsed_feed = FeedNormalizer::FeedNormalizer.parse remote_feed
      rescue Exception => e
        raise "Exception occurred when parsing feed #{feed[:name]} which was downloaded from #{feed[:url]}:\n\n" + e.to_s
      end

      raise "Feed #{feed[:name]} at #{feed[:url]} does not appear to be a parsable feed" unless parsed_feed

      # Sort and truncate the entries if max_entries argument is present
      if feed[:max_entries]
        parsed_feed.entries.sort!(&entry_sort_comparator)
        parsed_feed.entries.slice!(feed[:max_entries], parsed_feed.entries.size - feed[:max_entries])
      end
      
      # Store the entry sources. TODO: Store this information in the entries themselves
      parsed_feed.entries.each { |entry| entry_sources[entry] = feed }

      parsed_feed
    end

    def load_recipe(recipe)
      recipefile = File.join(@recipes_folder, recipe)
      if ! File.exist? recipefile
        $stderr.puts "ERROR: Recipe file #{recipefile} does not exist"
        exit(1)
      elsif ! File.readable? recipefile
        $stderr.puts "ERROR: Recipe file #{recipefile} is not readable"
        exit(1)
      end

      recipe = {}

      begin
        recipe = YAML::load_file(recipefile).symbolize_keys
      rescue Exception => e
        $stderr.puts "ERROR: Problem parsing recipe file #{recipefile}"
        $stderr.puts e
        exit(1)
      end

      recipe
    end

    def init_config(configfile)
      if ! File.exist? configfile
        $stderr.puts "ERROR: Configuration file #{configfile} does not exist"
        exit(1)
      elsif ! File.readable? configfile
        $stderr.puts "ERROR: Configuration file #{configfile} is not readable"
        exit(1)
      end

      config = {}

      begin
        config = YAML::load_file(configfile).symbolize_keys
      rescue Exception => e
        $stderr.puts "ERROR: Problem parsing configuration file #{configfile}"
        $stderr.puts e
        exit(1)
      end

      @recipes_folder = config[:recipes_folder]
      if ! File.exist? @recipes_folder
        $stderr.puts "ERROR: Recipes folder #{@recipes_folder} does not exist"
        exit(1)
      elsif ! File.readable? @recipes_folder
        $stderr.puts "ERROR: Recipes folder #{@recipes_folder} is not readable"
        exit(1)
      end

      @themes_folder = config[:themes_folder]
      if ! File.exist? @themes_folder
        $stderr.puts "ERROR: Themes folder #{@themes_folder} does not exist"
        exit(1)
      elsif ! File.readable? @themes_folder
        $stderr.puts "ERROR: Themes folder #{@themes_folder} is not readable"
        exit(1)
      end

      @user_agent = config[:user_agent] || 'Audrey 2.0 Feed Aggregator'
      @sort = (config[:sort] || 'reverse_chronological').to_sym

      if @email = config[:email]
        gem 'mail', '~> 2.2.5'
        require 'mail'
        # TODO: Check for required/consistent email config
      end

    end
  end

end