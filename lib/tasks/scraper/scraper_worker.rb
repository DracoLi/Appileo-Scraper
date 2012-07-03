module ScraperWorker

  # Constants
  include ScraperConstants

  # Scrape all the apps.
  # Returns a hash that contains the itunes information per store
  # and their respective reviews.
  def self.scrape_all(get_reviews)
  
    # Initialize variables
    apps = []
    
    # Iterate through every letter and scrape
    "A".upto("Z") do |letter|
      apps.concat(scrape_letter(letter, get_reviews)) 
    end
    
    # Scrape apps that start with numbers too
    apps.concat(scrape_letter("*", get_reviews))
    
    return apps
  end
  
  # Scrape only apps that start with the given letter.
  # Returns a hash that contains the itunes information per store
  # and their respective reviews.
  def self.scrape_letter(letter, get_reviews)
    
    # Initialize variables
    apps = []
    app_ids = Hash.new
    app_count = 0 # How many apps we have processed so far
    total_apps = 0 # Total number of apps for this letter
  
    # We are only interested in the apps ID
    app_ids = get_apps_per_letter(letter)
    total_apps = app_ids.length
    
    # Iterate through every app and scrape
    (app_ids).each do |app_id|
    
      apps << scrape_app(app_id, get_reviews)
      app_count += 1
      
      #TODO: REMOVE -- for testing only
      puts "scraping app %d out of %d" % [app_count, total_apps] if DEBUG
      break if (DEBUG and app_count >= DEBUG_MAX_APPS)
      
    end
    
    return apps
  end
  
  # Scrape only the app specified by app_id
  # Returns a hash that contains the itunes information per store
  # and their respective reviews
  def self.scrape_app(app_id, get_reviews)
    
    # Initialize variables
    apps = []
    
    (STORES).each do |store|
      
        # Initialize variables
        app = {}
        app["reviews"] = {}
        app["store"] = store[:code]
        
        # Make a call to the itunes API
        app.merge!(itunes_lookup(app_id, store[:code]))
        # Get the reviews
        app["reviews"] = fetch_reviews(app_id, store[:id]) if get_reviews
        
        apps << app
      
      end
      
    return apps
  end


  # Retrieves the list of apps with their respective IDs for a given letter
  # Letters can be A-Z or * for apps that start with a number.
  def self.get_apps_per_letter(letter)
  
    # Initialize variables
    apps_for_letter = []
  
    # Make sure our letter is capitalized, 
    # otherwise scraper URL will be malformed
    letter = letter.upcase
    
    # Determines if there is another page for the same letter
    next_available = true
    
    # page index
    page = 1
    
    while next_available
    
      # Format URL
      url = APP_STORE_URL % [letter, page]
      
      # Open and parse URL
      doc = Nokogiri::HTML(open(url))
      
      # As long as we have a NEXT link, we have another page to scrape
      next_available = doc.xpath(NEXT_AVAILABLE).length > 0
      
      # Move cursor
      start_element = doc.at(SCRAPE_START)
      
      # Get all the app links retrieve the APP ID
      app_links = start_element.xpath(SCRAPE_QUERY).each do |node|
      
        # Get the href attribute
        href = node[HREF]
        
        # use a regex to get the ID and add it to the array
        apps_for_letter << APP_ID_REGEX.match(href)[1]
      end
      
      # Move on to the next page
      page += 1
      
      #TODO: REMOVE - For testing only
      next_available = false if (DEBUG and page >= DEBUG_MAX_PAGES)
    
    end
    
    #TODO: REMOVE - For testing only
    puts "apps scraped for letter %s: %d" % [letter, apps_for_letter.length] if DEBUG
    
    # return the list of apps for the given letter
    return apps_for_letter
  end
  
  # Use itunes search API to get app information
  # country_code should be "us" or "ca" or any other country code
  def self.itunes_lookup(app_id, country_code)
    
    # format URL 
    url = ITUNES_LOOKUP_URL % [app_id, country_code]
    
    # make the API call
    result = JSON.parse(open(url).read)
    
    # Return based on if the app was found
    if result[RESULT_COUNT] == 0
      puts "Couldn't find app: %s in store: %s" % [app_id.to_s, country_code] if DEBUG 
      return {}
    else
      return result['results'][0]
    end
    
  end
  
  # Get reviews for a given app in the specified country.
  # store_id is the iTunes code for a given country store
  # Return a rating/subject/author/body hash array with the reviews.
  def self.fetch_reviews(app_id, store_id)
    
    # Initialize variables
    reviews = []
    more_available = true
    page = 0 # Page number
    
    # Loop while there are more reviews available
    while more_available
    
      # Create curl command
      cmd = REVIEW_CURL_CMD % [store_id, app_id, page]
      
      # Execute the command and get the XML
      rawxml = `#{cmd}`
      
      # Open parser for XML
      doc = Nokogiri::XML(rawxml)
      
      # Avoid an infinite loop by assuming there are no more reviews available
      more_available = false
      
      # Iterate through each review
      doc.search(REVIEW_QUERY, REVIEW_NAMESPACE).each do |node|
        review = {}
        
        strings = (node/:SetFontStyle)
        meta    = strings[2].inner_text.split(/\n/).map { |x| x.strip }
        
        # Create hash with information
        review["rating"]  = node.inner_html.match(REVIEW_RATING_REGEX)[1].to_i
        review["author"]  = meta[3]
        review["version"] = meta[7][REVIEW_VERSION_REGEX, 1] unless meta[7].nil?
        review["date"]    = meta[10]
        review["subject"] = strings[0].inner_text.strip
        review["body"]    = strings[3].inner_html.gsub(BR, NEW_LINE).strip
        
        # Store information
        reviews << review
        
        # Found reviews in this page, maybe there's another page. Let's check
        more_available = true
      end
      
      # Go through one review page only
      page += 1
    end
    
    #TODO: REMOVE - For testing only
    puts "Got %d reviews for app: %s in store %s" % [reviews.length, app_id, store_id] if DEBUG
    
    return reviews
  end
  
  
  # Reads information from the different iTunes RSS feeds
  # Returns a hash of app IDs with their given rank per category
  def self.get_rankings()
  
    # Initialize variables
    apps = {}
    
    # Get rankings per store
    (STORES).each do |store|
      
      apps[store[:code]] = {}
      
      # Get all the different categories links
      (RSS_LINKS).each do |link|
        
        # Reset rank for each category
        rank = 1
        
        # format URL
        url = link[:url] % [store[:code], RSS_LIMIT]
        
        # Read and parse the JSON RSS feed
        result = JSON.parse(open(url).read)
        
        #TODO: REMOVE - For testing only
        puts "parsing category %s. Found %d results for country %s" % [link[:name], result['feed']['entry'].length, store[:code]] if DEBUG
        
        result['feed']['entry'].each do |entry|
          
          # Retrieve the app id
          app_id = entry['id']['attributes']['im:id']
          
          # If app already exists in hash then add new rank, otherwise initialize it
          apps[store[:code]][app_id] = {} if !apps[store[:code]].has_key?(app_id)
          
          # Add app ID to the collection with its given rank
          apps[store[:code]][app_id][link[:name]] = rank
          
          # Increment rank
          rank += 1
          
        end
      end      
    end
    
    return apps
  end
  
end
