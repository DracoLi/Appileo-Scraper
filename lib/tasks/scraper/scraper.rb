require 'scraper_worker.rb'
require 'optparse'

module Scraper

  include ScraperWorker
  include ScraperCategorizer
  # Constants
  include ScraperConstants
  
  # This method calculates the weight of all the apps
  # has to be run over all apps and not just scrapped ones since it uses
  # the top number of ratings has a 100% of the ratings count level.
  def self.calculate_weight()
    apps = AppData.all
    # Get the top number of ratings and convert to integer in case it's none
    top_ratings_count = AppData.sort(:total_ratings_count).last.total_ratings_count.to_i
    
    # Run over all apps and calculate the weighted average
    apps.each do |app|
      # Make sure that the result saved are float
      x = app.total_ratings_count.to_f / top_ratings_count
      y = app.total_average_rating.to_f / MAX_RATING
      new_weight = GAMMA_RATINGS*x + (1-GAMMA_RATINGS)*y
      
      app.popularity_weight = new_weight
      app.save() if app.changed? && app.valid?
    end
    
    puts "Done calculated new weights for apps"
    
  end
  
  # Method that processes the AppData Document with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.app_processor(app, data)
    # Flag to mark if object was created or updated and
    # needs to be saved, written, to the db afterwards
    save_needed = false

    # Create hash with all values to be checked
    attributes = {
      # App
      :a_id => data['trackId'].to_f,
      :bundle_id => data['bundleId'],
      :name => data['trackName'],
      :summary => data['description'],
      :devices => data['supportedDevices'],
      :advisory => data['contentAdvisoryRating'],
      :game_center => data['isGameCenterEnabled'],
      :size => data['fileSizeBytes'].to_i,
      :lang => data['languageCodesISO2A'],
      :version => data['version'],
                  
      #Store
      :country => data['store'],
      :release_date => data['releaseDate'],
      :link => data['trackViewUrl'],
      
      :total_ratings_count => data['userRatingCount'].to_i,
      :total_average_rating => data['averageUserRating'].to_f,
      :current_ratings_count => data['userRatingCountForCurrentVersion'].to_i,
      :current_average_rating => data['averageUserRatingForCurrentVersion'].to_f,           
                  
      # Price            
      :amount => data['price'].to_f,
      :currency => data['currency'],
      
      # Publisher       
      :pub_id => Float(data['artistId']).to_f,
      :pub_name => data['artistName'],
      :pub_company => data['sellerName'],
      :pub_link => data['artistViewUrl'],
      
      # Pics
      :pic_iphone => data['screenshotUrls'],
      :pic_ipad => data['ipadScreenshotUrls'],
      :pic_icon60 => data['artworkUrl60'],
      :pic_icon100 => data['artworkUrl100'],
      :pic_icon512 => data['artworkUrl512']
    }
    
    if app == nil
      # If app is nil, create a new one
      app = AppData.new(attributes)
      #puts AppData.name + ": Data needs to be created"
    else
      # Assign the new set of attributes
      app.attributes = attributes
    end
      
    # Check if app is valid with the new set of attributes
    if app.invalid?
      # Check if app_data attributes are valid otherwise inform about errors
      #puts AppData.name + ": Error validating data"
      app.errors.each { |error, message| puts "-> #{error}: #{message}" }
      return [false, app]
    else
      # If validation passed, check if needs to save
      if app.changed?
        #puts AppData.name + ": Data needs to be updated"
        return [true, app]
      else
        # Nothing to change
        #puts AppData.name + ": Data up to date"
        return [false, app]
      end
    end
  end
  
  # Method that processes the Reviews Embedded Document
  # inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.reviews_data_processor(app, reviews)
    
    # Keep a reference to the last day of the reviews that are already saved
    # internally in the database. This will allow us to add all later reviews,
    # and check only the last date for additional reviews that do not exist
    last_date = nil
    if !app.review.empty?
      #puts Review.name + ": Found internal reviews"
      if reviews == nil
        # If reviews were previously recorded and no results scrapped
        # remove all reviews from file
        #puts Review.name + ": Removing all previous reviews since empty set scrapped"
        app.review.clear
        return true
      end
      # If there are reviews, get the latest review datetime
      # in order to make sure to insert only the ones that were
      # recorded afterwards
      app.review.each do |review|
        last_date = review.date if last_date == nil || (review.date != nil && review.date > last_date)
      end
    elsif reviews == nil || reviews.length == 0
      # If no reviews previously recorded and no results scrapped, nothing to change.
      #puts Review.name + ": No external reviews found"
      return false
    end
    
    #puts Review.name + ": Found extrenal reviews"
    
    # Keep flag if save is needed
    save_needed = false
    
    # Iterate through all reviews
    reviews.each do |review|
      # Create hash with all values to be checked
      # Keys have to be in 'string' format instead of :string
      # in order to be able to match the keys to the ones
      # returned in the data using 'diff' on the hashes
      attributes = {
        'body' => review['body'],
        'subject' => review['subject'],
        'rating' => review['rating'],
        'author' => review['author'],
        'version' => review['version'],
        'date' => review['date']
      }
      
      # Initialize flag to add the review later
      add_review = false                
      
      if (review['date'] != nil) && (last_date == nil || Date.parse(review['date']) > last_date) 
        # If review was recorded later then the latest review,
        # mark save needed in order to add it to the database
        add_review = true
      elsif (review['date'] != nil) && (last_date == nil || Date.parse(review['date']) == last_date)
        # If review was recorded at the same day as the latest review,
        # check if the values already exists, otherwise mark save needed
        # in order to add it to the database
        
        # keep flag if exact review was found
        review_found = false
        app.review.each do |app_review|
          # Check if there is a review with exactly the same attributes
          hash_diff_keys =  attributes.diff(app_review.attributes).keys
          
          # Clean for Ruby Attributes
          # NOTE: If changes are made to the REVIEW model, changes might be
          # requried to be introduced here as well
          hash_diff_keys.delete('_id')
          hash_diff_keys.delete('created_at')
          hash_diff_keys.delete('updated_at')

          if (hash_diff_keys.length == 0)
            review_found = true
            break
          end
        end
        
        # If no review was found, save the new one
        if !review_found
          add_review = true  
          save_needed = true
        end 
      end
      
      if add_review
        app.review << Review.new(attributes)
      end
    end
    
    return save_needed
    
  end
  
  # Method that processes the Rank Embedded Document
  # inside Store inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.rankings_data_processor(app, ranking)
    # Create hash with all values to be checked
    # Keys have to be in 'string' format instead of :string
    # in order to be able to match the keys to the ones
    # returned in the data using 'diff' on the hashes
    
    if ranking != nil
      attributes = {'top_free_apps_iphone' => ranking.has_key?('top_free_apps_iphone') ? ranking['top_free_apps_iphone'] : nil,
                    'top_paid_apps_iphone' => ranking.has_key?('top_paid_apps_iphone') ? ranking['top_paid_apps_iphone'] : nil,
                    'top_gros_apps_iphone' => ranking.has_key?('top_gros_apps_iphone') ? ranking['top_gros_apps_iphone'] : nil,
                    'top_free_apps_ipad' => ranking.has_key?('top_free_apps_ipad') ? ranking['top_free_apps_ipad'] : nil,
                    'top_paid_apps_ipad' => ranking.has_key?('top_paid_apps_ipad') ? ranking['top_paid_apps_ipad'] : nil,
                    'top_gros_apps_ipad' => ranking.has_key?('top_gros_apps_ipad') ? ranking['top_gros_apps_ipad'] : nil,
                    'new_apps' => ranking.has_key?('new_apps') ? ranking['new_apps'] : nil,
                    'new_free_apps' => ranking.has_key?('new_free_apps') ? ranking['new_free_apps'] : nil,
                    'new_paid_apps' => ranking.has_key?('new_paid_apps') ? ranking['new_paid_apps'] : nil }
      
      
    else
      attributes = {'top_free_apps_iphone' => nil,
                    'top_paid_apps_iphone' => nil,
                    'top_gros_apps_iphone' => nil,
                    'top_free_apps_ipad' => nil,
                    'top_paid_apps_ipad' => nil,
                    'top_gros_apps_ipad' => nil,
                    'new_apps' => nil,
                    'new_free_apps' => nil,
                    'new_paid_apps' => nil }  
    end
    
    app.attributes = attributes
      
    # Check if app is valid with the new set of attributes
    if app.invalid?
      # Check if app_data attributes are valid otherwise inform about errors
      #puts AppData.name + ": Error validating data for Ranking"
      app.errors.each { |error, message| puts "-> #{error}: #{message}" }
      return [false, app]
    else
      # If validation passed, check if needs to save
      if app.changed?
        #puts AppData.name + ": Data needs to be updated for Ranking"
        return [true, app]
      else
        # Nothing to change
        #puts AppData.name + ": Data up to date for Ranking"
        return [false, app]
      end
    end
    
  end

  def self.scrape_apps(new_apps, rankings, categorize)
    
    # Load the categories and interests to the memory in order not to
    # read the files again and use it for all apps if categorization requested
    categories = ScraperCategorizer.get_categories()
    interests = ScraperCategorizer.get_interests()
    sub_categories = ScraperCategorizer.get_subcategories(categories)

    # Iterate on all apps that were retrieved
    (new_apps).each do |app_data|
      
      # If app data didn't exist move to the next entry
      if app_data == nil || app_data.empty? || !app_data.has_key?('trackId')
        next
      end

      # Get the app id and country that should be unique together      
      app_id = Float(app_data['trackId'])
      country = app_data['store']
      puts "\nProcessing app id: " + String(app_data['trackId']) + " in " + country
      
      # Try to get data from collection, otherwise create new one
      # note: this won't validate or save to database yet
      app = AppData.find_all_by_a_id_and_country(app_id, country)
      raise "Error: multiple results returned for app id : " + app_id + 
            " and country " + country if app.length > 1 
      
      # Run the processor in order to check for creation or update of values
      # Init flag that marks if app needs to be saved back to database
      is_save_needed_app = false
      if app.length == 0
        # If app not found, pass nil 
        is_save_needed_app, app = app_processor(nil, app_data)
      else
        # If app found, pass the app
        is_save_needed_app, app = app_processor(app[0], app_data)
      end
      
      # Get review and run Reviews processor
      reviews = app_data['reviews']
      # Init flag that marks if app needs to be saved back to database
      is_save_needed_reviews = reviews_data_processor(app, reviews)
      
      # Init flag that marks if ranking needs to be saved back to database
      is_save_needed_ranking = false  
      # Check if rankings are passed and need to be processed  
      if rankings != nil
        
        ranking = nil
        app_id_string = String(Integer(app_id))
        if rankings.has_key?(country) && rankings[country].has_key?(app_id_string)
          ranking = rankings[country][app_id_string]
        end
        is_save_needed_ranking, app = rankings_data_processor(app, ranking)
      end
      
      # Init flag that marks if categorization needs to be saved to database
      is_save_needed_categorize = false
      # In order to categorize the apps as they are scrapped and before
      # saving them into the database, we use the categories and interests
      # that were previously read to memory, and calling categorization per app
      if categorize
        # Catch if app categorization changed for category, subcategory, or
        # interest
        is_save_needed_categorize, app =
          ScraperCategorizer.categorize_app(app, categories, interests, sub_categories)
      end
      
      # Check all flags to see if anything has change and save is needed
      if is_save_needed_app || is_save_needed_reviews ||
         is_save_needed_ranking || is_save_needed_categorize
        if !app.save
           puts AppData.name + ": DATA FAILED TO SAVE\n\n"
        else
           puts AppData.name + ": DATA SAVED\n\n" 
        end
      else
        puts AppData.name + ": NO UPDATES\n\n"
      end
   end
   
  end
  
#-------------------------- Main Scrape Methods ------------------------------#
  
  # Method to scrape all apps from the app store
  def self.scrape_apps_all(rankings, get_reviews, categorize)
    scrape_apps(ScraperWorker.scrape_all(get_reviews),
                rankings, categorize)
  end
  
  # Method to scrape all apps in a certain letter from the app store
  def self.scrape_apps_letter(letter, rankings, get_reviews, categorize)
    scrape_apps(ScraperWorker.scrape_letter(letter, get_reviews),
                rankings, categorize)
  end
  
  # method to scrape a specific app
  def self.scrape_apps_id(app_id, rankings, get_reviews, categorize)
    scrape_apps(ScraperWorker.scrape_app(app_id, get_reviews),
                rankings, categorize)
  end
  
  # method to scrape all apps with rankings
  def self.scrape_apps_ranked(rankings, get_reviews, categorize)
    if (rankings != nil)
      rankings.each do |country, ranks|
        ranks.each do |app_id, app_data|
          scrape_apps(ScraperWorker.scrape_app(app_id, get_reviews),
                      rankings, categorize)
        end
      end
    end
  end
  
end

#------------------------------------ RUN ------------------------------------#

# first try and show proper usage if arguments aren't well-formed:
def usage
  abort "usage: rails runner #{__FILE__} -- [options]"
end

# Check if -- exists, if not, exit and show usage
usage unless ARGV.include?("--")

# Clean up ARGV up to -- :
loop { break if ARGV.shift == "--" }

# Holds the options parsed from the command-line
options = {}

optparse = OptionParser.new do |opts|
  # In order to only categorize all the apps without scrapping, the script has
  # to be run with a -c flag only. Otherwise, if certain ids are provided in a
  # list, they will be scraped, and with no ids the scraper will depends on the 
  # options, such as per letter or all. Including the -c flag while scraping
  # will categorize the apps as well as part of the process.

  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: scraper.rb -- [options] [id1 id2 ...  - Priority 1]"
 
  # Options (with priority for execution decision)
  # Priority 1 - specific ids provided
  # Priority 2 - specific letter provided
  # Priority 3 - ranked apps requested
  # Priority 4 - all apps requested
  # Categorize flag - categorize apps as well or not, or just categorize apps
  # Reviews Flag - get reviews as well or not
   
  options[:reviews] = false
  opts.on( '-r', '--reviews', 'Scrape reviews as well if set' ) do
    options[:reviews] = true
  end
  
  options[:categorize] = false
  opts.on('-c', '--categorize', 'Categorize apps') do
    options[:categorize] = true
  end
  
  options[:letter] = nil
  opts.on( '-l', '--letter LETTER', 'Scrape apps in letter - Priority 2' ) do |letter|
    options[:letter] = letter
  end
  
  options[:rankings] = false
  opts.on( '-R', '--ranked', 'Scrape ranked apps - Priority 3' ) do
    options[:rankings] = true
  end
  
  options[:all] = false
  opts.on( '-a', '--all', 'Scrape all apps - Priority 4' ) do
    options[:all] = true
  end
 
  # Display the help screen and exit
  opts.on( '-h', '--help', 'Show help' ) do
    puts opts
    exit
  end
end

# Parses ARGV and removes any options found there,
# as well as any parameters for the options.
optparse.parse!

# What's left is the list of ids to scrape
ids = ARGV

# Find which function to execute
# Note: The order of checks is important, and once got into an if statement
# the otherones should not be checked since program exists.

# First check if rankings are needed, if so get them
rankings = nil
if options[:rankings]
  rankings = ScraperWorker.get_rankings
end

# If specific ids were found, scrape these apps only
if !ids.empty?  
  ids.each do |id|
    Scraper.scrape_apps_id(id, rankings,
                           options[:reviews], options[:categorize])
  end
  Scraper.calculate_weight()
  exit
end

# If specific letter was found, scrape the letter only
if options[:letter] != nil
  letter = options[:letter]
  
  if letter.length != 1
    # Check that letter only one char, otherwise exit
    puts optparse
    exit
  end
  
  puts "Scrapping letter: " + letter
  Scraper.scrape_apps_letter(letter, rankings,
                             options[:reviews], options[:categorize])
  Scraper.calculate_weight()
  exit 
end

# If all apps flag is set, scrape all apps
if options[:all]
  puts "Scrapping all apps"
  Scraper.scrape_apps_all(rankings,
                          options[:reviews], options[:categorize])
  Scraper.calculate_weight()
  exit 
end

# If rankings is the only flag set, get all ranked apps
if options[:rankings]
  puts "Scrapping all ranked apps"
  Scraper.scrape_apps_ranked(rankings,
                             options[:reviews], options[:categorize])
  Scraper.calculate_weight()
  exit 
end

# If categorize is the only flag set, just categorize apps
if options[:categorize]
  puts "Categorizing all apps"
  ScraperCategorizer.categorize_all(AppData.all)
  exit
end

# If reached to this point, show the usage screen
puts optparse
exit