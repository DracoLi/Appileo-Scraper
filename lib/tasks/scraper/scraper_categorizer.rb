module ScraperCategorizer
  
  # Path to the categories and interest files
  CATEGORY_FILE = "#{Rails.root}/app/assets/data/category_tags.json"
  INTEREST_FILE = "#{Rails.root}/app/assets/data/interest_tags.json"
  
  # Regex to split array
  SCAN_REGEX    = /[\w-]+/
  
  # key name for the keywords to match
  KEYWORD_MATCH       = 'matches'
  # key name for the minimum number of required tags
  KEYWORD_MIN_TAGS    = 'min_tags'
  # Multiplier for when a keyword match is found on the title
  TITLE_MATCH_MULT    = 3
  # Minimum number of matches before tagging
  KEY_MIN_MATCHES     = 1
  
  # sub categories key name
  SUB_CAT       = 'subcats'
  
  
  # Get the categories and return them
  def self.get_categories()
    categories = {}
    
    # Open and parse categories file
    File.open(CATEGORY_FILE, 'r') do |f|
      categories = ActiveSupport::JSON.decode(f.read.downcase)
    end
    
    return categories
  end
  
  # Get the categories and return them
  def self.get_interests()
    interests = {}
    
    # Open and parse interest file
    File.open(INTEREST_FILE, 'r') do |f|
      interests = ActiveSupport::JSON.decode(f.read.downcase)
    end
    
    return interests
  end
  
  # Categorizes the list of all apps
  def self.categorize_all(apps)
    
    # Initialize the container of the apps that will include subarrays of
    # save_needed and the app itself
    new_apps = []
    
    # Get the categories and interests only once from parsing the files
    categories = get_categories()
    interests = get_interests()
    
    # Iterate through the list of apps and categorize them
    apps.each do |app|
      new_apps << categorize_app(app, categories, interests)
    end
    
    # Return the new list that includes arrays of save_needed flags and apps
    return new_apps
  end

  # Categorize a specific app. Sets main category, sub category and interests
  # Returns a flag if any change has to be saved and the app itself
  def self.categorize_app(app, categories, interests)
  
    # If app doesn't exist, return no save needed and nil
    return false, nil if app == nil
    
    # Get the highest ranked category
    category = keyword_match(app, categories)[0]
    
    # If category found check for subcategory
    if category != nil
      puts category
      # Get the sub categories for highest ranked category
      sub_categories = categories[category][SUB_CAT]
      sub_category = keyword_match(app, sub_categories)[0]
    end
    
    # Get interests for given app
    interests = keyword_match(app, interests, false)
    
    # Update app object categorization attributes
    attributes = {
      'category' => category,
      'sub_category' => sub_category,
      'interest' => interests
    }
    
    # Assign the new set of attributes
    app.attributes = attributes
    
    # Check if app is valid with the new set of attributes
    if app.invalid?
      # Check if app_data attributes are valid otherwise inform about errors
      puts AppData.name + ": Error validating data"
      app.errors.each { |error, message| puts "-> #{error}: #{message}" }
      return [false, app]
    else
      # If validation passed, check if needs to save
      return [app.changed?, app]
    end
  end
  
  # Return a list of matching keywords from the given list.
  # When top=true it returns only the top hit, otherwise return the entire list 
  def self.keyword_match(app, keyword_list, top=true)
    
    # Parse the title and description of the app and count the number of 
    # occurences of each word
    title_words   = count_word_freq(app.name.downcase.scan(SCAN_REGEX))
    summary_words = count_word_freq(app.summary.downcase.scan(SCAN_REGEX))
    
    # Initialize rank hash
    rank = Hash.new(0)
    
    # Find all matching keywords and assign a rank to each one
    keyword_list.each do |keyword_key, keyword_value|
      
      # Number of keyword hits
      count_hits = 0
      # Minimum number of hits before a match can be considered
      min_hits = keyword_value[KEYWORD_MIN_TAGS] || KEY_MIN_MATCHES
      
      # Iterate through each keyword
      keyword_value[KEYWORD_MATCH].each do |match|
        
        # create singular and plural form of the keyword
        match_singular = match.downcase.singularize
        match_plural = match.downcase.pluralize
        
        # match against singular and plural forms of the keyword
        [match_singular, match_plural].each do |keyword|
          
          # match title against keyword
          if title_words.key? keyword
            rank[keyword_key] += TITLE_MATCH_MULT * title_words[keyword]
            count_hits += 1
          end

          # match description against keyword
          if summary_words.key? keyword
            rank[keyword_key] += summary_words[keyword]
            count_hits += 1
          end

        end
      end
      
      # Remove match if it doesn't have the minimum number of hits
      if count_hits < min_hits
        rank.delete(keyword_key)
      end

    end

    result = []
    # Return empty if we have no matches 
    return result if rank.length == 0
    
    # Sort
    rank = rank.sort_by{|k,v| v}.reverse
    
    # Return top hit or list of hits based on the top argument  
    top ? result << rank[0][0] : rank.each { |keyword| result << keyword[0] } 
    
    return result
  end
  
  
  # Return a hash with the word and the count of how many times the word
  # appears in the word_list 
  def self.count_word_freq(word_list)
    freq = Hash.new(0)
    
    for word in word_list
      freq[word] += 1
    end
    
    return freq
  end

end
