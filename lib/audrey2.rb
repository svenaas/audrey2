require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'haml'

module Audrey2

  class Aggregator
    def initialize(configfile)
      init_config(configfile)
    end

    def feed_me(recipe_name)
      begin
        # Load recipe and theme and make sure everything is in order
        recipe = load_recipe(recipe_name)
        init_theme(recipe['theme'])
        output_file = recipe['output_file']
        verify_output_file(output_file)
        max_entries = recipe['max_entries'] || 1000

        # Download and parse the feeds
        entry_sources = {}
        feeds = recipe['feeds'].collect { |feed| parse_feed(feed, entry_sources) }

        # Aggregate and sort the entries
        entries = []
        feeds.each { |feed| entries += feed.entries }
        sort!(entries)

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
        $stderr.puts "An exception occurred while running recipe #{recipe_name}:\n\n#{e}\n#{e.backtrace}"
        if @email
          email(<<-EOF
An exception occurred while running recipe #{recipe_name}

Exception: #{e}

Backtrace:

#{e.backtrace}
EOF
          )
        else
          exit(1)
        end
      end
    end

  protected
    def email(e)
      return unless @email

      mail = Mail.new
      mail[:from] =    @email['from']
      mail[:to] =      @email['to']
      mail[:subject] = "[AUDREY 2.0] Exception Notification"
      mail[:body]    = e

      case @email['via']
      when 'sendmail'
        mail.delivery_method :sendmail
      when 'smtp'
        raise "Missing SMTP configuration" unless @email['smtp']
        smtp = {
          :address        => @email['smtp']['server']         || 'localhost',
          :port           => @email['smtp']['port']           || 25
        }
        smtp[:domain]         = @email['smtp']['domain']         if @email['smtp']['domain']
        smtp[:user_name]      = @email['smtp']['user_name']      if @email['smtp']['user_name']
        smtp[:password]       = @email['smtp']['password']       if @email['smtp']['password']
        smtp[:authentication] = @email['smtp']['authentication'] if @email['smtp']['authentication']
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
          $stderr.puts "ERROR: Helper file #{helper_file} is not readable"
          exit(1)
        end
        @helper_code = File.open(helper_file) { |f| f.read }
      end
    end

    # Uses the sort order specified in configuration
    def sort!(entries)
      case @sort
      when 'reverse-chronological'
        entries.sort! {|a, b| b.date_published <=> a.date_published } # Reverse chronological
      end
    end

    def parse_feed(feed, entry_sources)
      remote_feed = nil
      begin
        remote_feed = open(feed['url'], "User-Agent" => @user_agent)
      rescue Exception => e
        raise "Exception occurred when opening feed #{feed['name']} at #{feed['url']}:\n\n" + e.to_s
      end

      parsed_feed = nil
      begin
        parsed_feed = FeedNormalizer::FeedNormalizer.parse remote_feed
      rescue Exception => e
        raise "Exception occurred when parsing feed #{feed['name']} which was downloaded from #{feed['url']}:\n\n" + e.to_s
      end

      raise "Feed #{feed['name']} at #{feed['url']} does not appear to be a parsable feed" unless parsed_feed

      parsed_feed.entries.each { |entry| entry_sources[entry] = feed }

      parsed_feed
    end

    def load_recipe(recipe)
      recipefile = File.join(@recipes_folder, recipe)
      if ! File.exist? recipefile
        $stderr.puts "ERROR: Recipe #{recipefile} does not exist"
        exit(1)
      elsif ! File.readable? recipefile
        $stderr.puts "ERROR: Recipe file #{recipefile} is not readable"
        exit(1)
      end
      YAML::load_file(recipefile)
    end

    def init_config(configfile)
      if ! File.exist? configfile
        $stderr.puts "ERROR: Configuration file #{configfile} does not exist"
        exit(1)
      elsif ! File.readable? configfile
        $stderr.puts "ERROR: Configuration file #{configfile} is not readable"
        exit(1)
      end

      config = YAML::load_file(configfile)

      @recipes_folder = config['recipes_folder']
      if ! File.exist? @recipes_folder
        $stderr.puts "ERROR: Recipes folder #{@recipes_folder} does not exist"
        exit(1)
      elsif ! File.readable? @recipes_folder
        $stderr.puts "ERROR: Recipes folder #{@recipes_folder} is not readable"
        exit(1)
      end

      @themes_folder = config['themes_folder']
      if ! File.exist? @themes_folder
        $stderr.puts "ERROR: Themes folder #{@themes_folder} does not exist"
        exit(1)
      elsif ! File.readable? @themes_folder
        $stderr.puts "ERROR: Themes folder #{@themes_folder} is not readable"
        exit(1)
      end

      @user_agent = config['user_agent'] || 'Audrey 2.0 Feed Aggregator'
      @sort = config['sort'] || 'reverse-chronological'

      if @email = config['email']
        gem 'mail', '~> 2.2.5'
        require 'mail'
        # TODO: Check for required/consistent email config
      end

    end
  end

end