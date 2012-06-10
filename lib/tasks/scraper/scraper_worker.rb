module ScraperWorker

  # Constants
  include ScraperConstants

  # Store the list of all the apps with their respective IDs
  def self.scrape_all()
  
    apps = Hash.new
    app_ids = Hash.new
  
    # TODO: REMOVE - Time benchmark for performance
    start_time = Time.now if DEBUG
  
    # TODO: REPLACE upto("A") with ("Z") to scrape all apps
    "A".upto("A") {
      |letter|
      app_ids.merge!(scrape_letter(letter))
    }
    
    # Scrape apps that start with numbers too
    app_ids.merge!(scrape_letter("*"))
    
    # We are only interested in the apps ID
    app_ids = app_ids.keys
    
    # How many apps we have processed so far
    app_count = 0
    
    (app_ids).each do |app|
    
      # Initialize variables
      apps[app] = Hash.new
      apps[app][:result] = Hash.new
      apps[app][:reviews] = Hash.new
    
      # Get app information and reviews for each store
      (STORES).each do |store|
      
        # Make a call to the itunes API
        apps[app][:result][store[:code]] = itunes_lookup(app, store[:code])
        
        # Get the app reviews
        apps[app][:reviews][store[:code]] = fetch_reviews(app, store[:id])
      
      end
      
      app_count += 1
      
      #TODO: REMOVE -- for testing only
      break if (DEBUG and app_count >= DEBUG_MAX_APPS)
      
    end

    if DEBUG
      exec_time = Time.now - start_time
      puts "Execution time #{exec_time} seconds."
    end
    
    return apps
  end


  # Retrieves the list of apps for a given letter
  # Letters can be A-Z or * for apps that start with a number
  def self.scrape_letter(letter)
  
    apps_for_letter = Hash.new
  
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
      
      #puts url if DEBUG
      
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
        
        # use a regex to get the ID
        app_id = APP_ID_REGEX.match(href)[1]
        
        # Add the ID to the Hash
        apps_for_letter[app_id] = 1
      end
      
      # Move on to the next page
      page += 1
      
      #TODO: REMOVE - For testing only
      next_available = false if (DEBUG and page >= DEBUG_MAX_PAGES)
    
    end
    
    #TODO: REMOVE - For testing only
    if DEBUG
      puts "apps scraped for letter %s: %d" % [letter, apps_for_letter.keys.length]
      puts ""
    end
    
    # return the list of apps for the given letter
    return apps_for_letter
  end
  
  
  # Use itunes search API to get app information
  def self.itunes_lookup(app_id, country_code)
    url = ITUNES_LOOKUP_URL % [app_id, country_code]
    
    # make the API call
    result = JSON.parse(open(url).read)
    
    # Determine if the app was found
    total = result[RESULT_COUNT]
    
    if total == 0
      puts "Couldn't find app " + app_id.to_s if DEBUG
      return {}
    else
    
      #puts result['results'][0]['screenshotUrls']
      #puts "app name: %s, url: %s" % [result['results'][0]['trackName'], url] if DEBUG
    
      return result['results'][0]
    end
  end
  
  
  # return a rating/subject/author/body hash array with the reviews
  def self.fetch_reviews(app_id, store_id)
    reviews = []
    
    # Page number
    page = 0
    
    more_available = true
    
    while more_available
    
      # Create curl command
      cmd = REVIEW_CURL_CMD % [store_id, app_id, page]
      
      #puts cmd if DEBUG
      
      # Execute the command and get the XML
      rawxml = `#{cmd}`
      
      # Open parser for XML
      doc = Nokogiri::XML(rawxml)
      
      # Avoid an infinite loop by assuming there are no more reviews available
      more_available = false
      
      doc.search(REVIEW_QUERY, REVIEW_NAMESPACE).each do |node|
        review = {}
        
        strings = (node/:SetFontStyle)
        meta    = strings[2].inner_text.split(/\n/).map { |x| x.strip }
        
        # Create hash with information
        review[:rating]  = node.inner_html.match(REVIEW_RATING_REGEX)[1].to_i
        review[:author]  = meta[3]
        review[:version] = meta[7][REVIEW_VERSION_REGEX, 1] unless meta[7].nil?
        review[:date]    = meta[10]
        review[:subject] = strings[0].inner_text.strip
        review[:body]    = strings[3].inner_html.gsub(BR, NEW_LINE).strip
        
        # Store information
        reviews << review
        
        # Found reviews in this page, maybe there's another page. Let's check
        more_available = true
      end
      
      page += 1
      
      #puts "page: %d, reviews so far: %d" % [page, reviews.length] if DEBUG 
    end
    
    if DEBUG
      puts "Got %d reviews for app: %s in store %s" % [reviews.length, app_id, store_id]
      puts ""
    end
    
    return reviews
  end
  
  
  # Returns a hash of app IDs with their given rank per category
  def self.get_rankings()
  
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
        
        if DEBUG
          #puts "parsing url %s" % url  
          #puts result['feed']['entry'].length
        end
        
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

a = ScraperWorker.get_rankings

