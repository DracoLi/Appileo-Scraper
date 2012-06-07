class Scraper

  # Constants
  include ConstModule

  # attr_accessor -- both read and write
  # attr_reader -- just read
  # attr_writer -- just write

  attr_reader :apps, :app_ids
  
  private :app_ids

  def initialize()
    @apps = Hash.new
    @app_ids = Hash.new
  end

  # Store the list of all the apps with their respective IDs
  def scrape_all()
    "A".upto("Z") {
      |letter|
      @app_ids.merge!(scrape_letter(letter))
    }
    
    # Scrape apps that start with numbers too
    @app_ids.merge!(scrape_letter("*"))
    
    # We are only interested in the apps ID
    @app_ids = @app_ids.keys
    
    # Make a call to the itunes API for each store
    (STORES).each do |store|
    
      app_count = 0
    
      (@app_ids).each do |app|
        itunes_lookup(app, store[:code])
        
        app_count += 1
        
        #TODO: REMOVE -- for testing only
        break if (DEBUG and app_count >= DEBUG_MAX_APPS)
      end
    end
  end


  # Retrieves the list of apps for a given letter
  # Letters can be A-Z or * for apps that start with a number
  def scrape_letter(letter)
  
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
      
      puts url if DEBUG
      
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
        app_id = /\/id(.*)\?/.match(href)[1]
        
        # Add the ID to the Hash
        apps_for_letter[app_id] = 1
      end
      
      # Move on to the next page
      page += 1
      
      #TODO: REMOVE - For testing only
      next_available = false if (DEBUG and page >= DEBUG_MAX_PAGES)
    
    end
    
    # return the list of apps for the given letter
    return apps_for_letter
    
  end
  
  # Use itunes search API to get app information
  def itunes_lookup(app_id, country_code)
    url = ITUNES_LOOKUP_URL % [app_id, country_code]
    
    puts url if DEBUG
    
    # make the API call
    result = JSON.parse(open(url).read)
    
    # Determine if the app was found
    total = result[RESULT_COUNT]
    
    if total == 0
      puts "Couldn't find app " + app_id.to_s()
    end
    
    
    #puts result['results'][0]['screenshotUrls']
    puts result['results'][0]['trackName'] if DEBUG
  end
  
end