module ScraperCategorizer
  
  # Constants
  include ScraperConstants
  
  # Get the categories and return them
  def self.get_categories()
    categories = {}
    
    # Open and parse categories file
    File.open(CATEGORY_FILE, 'r') do |f|
      categories = ActiveSupport::JSON.decode(f.read.downcase)
    end
    
    return categories
  end

  def self.get_subcategories(categories)
    sub_categories = {}

    categories.each do |category_key, category_value|
      category_value[SUB_CAT].each do |sub_key, sub_value|
        # Keep track of the parent category
        sub_value[SUB_CAT_PARENT] = category_key
        sub_categories[sub_key] = sub_value
      end
    end
    
    return sub_categories
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
    
    # Get all subcategories
    sub_categories = get_subcategories(categories)
    
    # Iterate through the list of apps and categorize them
    apps.each do |app|
      new_apps << categorize_app(app, categories, interests, sub_categories)
    end
    
    # Return the new list that includes arrays of save_needed flags and apps
    return new_apps
  end

  # Categorize a specific app. Sets main category, sub category and interests
  # Returns a flag if any change has to be saved and the app itself
  def self.categorize_app(app, categories, interests, sub_categories)
  
    # If app doesn't exist, return no save needed and nil
    return false, nil if app == nil
    
    # Get the highest ranked category
    category = keyword_match(app, categories)[0]
    
    # If category found check for specific subcategory, otherwise search in
    # all subcategories
    if category != nil
      # Get the sub categories for highest ranked category
      sub_category = keyword_match(app, categories[category][SUB_CAT])[0]
    else
      # Search in all subcategories
      sub_category = keyword_match(app, sub_categories)[0]
      
      # If we matched a subcategory, assign the corresponding parent category
      category = sub_categories[sub_category][SUB_CAT_PARENT] if sub_category != nil
    end
    
    # Get interests for given app
    interests = keyword_match(app, interests, false)
    
    # Update app object categorization attributes
    attributes = {
      'category' => category,
      'sub_category' => sub_category,
      'interests' => interests
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
    
    max_len = get_keyword_max_words(keyword_list)
    
    # Parse the title and description of the app and count the number of 
    # occurences of each word
    title_words   = count_word_freq(app.name.downcase.scan(SCAN_REGEX))
    summary_words = count_word_freq(app.summary.downcase.scan(SCAN_REGEX))
    
    (2..max_len).each do |i|
      # This return an array of arrays with the matches
      result_title = app.name.downcase.scan(create_multiword_regex(i))
      result_summary = app.summary.downcase.scan(create_multiword_regex(i))
      
      # Create a single array so we can count word frequency to determine
      # category
      keywords_title = []
      keywords_summary = []
      result_title.each {|phrase| keywords_title << phrase.join }
      result_summary.each {|phrase| keywords_summary << phrase.join }
      
      # Merge with our existing list
      title_words.merge!(count_word_freq(keywords_title))
      summary_words.merge!(count_word_freq(keywords_summary))
    end

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
  
  # Returns the maximum number of words a set of keywords has.
  # This allows to create the regex to match multiple words
  def self.get_keyword_max_words(categories)
    keywords = []
    categories.values.each { |category| keywords << category[KEYWORD_MATCH] }
    keywords = keywords.flatten
    
    max_len = 2
    keywords.each { |keyword| max_len = keyword.split.length if keyword.split.length > max_len }
    
    return max_len
  end
  
  # Creates the regular expression that matches exactly LENGTH words
  def self.create_multiword_regex(length)
    
    # We cannot make a multiword regular expression with less than 2 words
    return if length < 2
    
    # Create the regex.
    multi_word = WORD_SPACE_REGEX.to_s * (length - 1)
    
    # Return the regex
    return /(\w{1,}(?=#{multi_word}))/
  end

end
