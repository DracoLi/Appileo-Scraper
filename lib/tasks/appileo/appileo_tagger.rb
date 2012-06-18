require 'scraper_parser_helper.rb'

module AppileoTagger
  
  include AppileoParserHelper
  
  CATEGORY_FILE = \
    "#{Rails.root}/app/assets/data/category_tags.json"
  INTERESTS_FILE = \
    "#{Rails.root}/app/assets/data/category_tags.json"  

  # This method takes an app and returns the
  #  app with a specific category or categories
  def self.parse_for_app_categories(app)
    
    # Get matches for different part of the app
    title_matches = categories_in_words(app.name)
    content_matches = categories_in_words(app.summary)
    
    # Add in good reviews to the search text as well
    review_text = ""
    app.stores.reviews.each do |review|
      if review.rating > 4
        review_text += "#{review.subject}\n#{review.body}"
      end
    end
    quality_review_matches = categories_in_words(app.review_text)
      
    # TODO: Rank all the category matches
    all_categories = merge_categories(title_matches, content_matches)
    all_categories = merge_categories(all_categories, quality_review_matches)
  end
  
  # Returns the categories that is matched in the words
  def self.categories_in_words(words)
    # Get categories in the file
    all_categories = nil
    File.open(CATEGORY_FILE, 'r') do |f|
      all_categories = ActiveSupport::JSON.decode f.read 
    end
    
    # Check if words match any of our categories
    matched_categories = []
    all_categories.each_pair do |cat_name, cat_value|
      # Check if main category matches
      main_matches = false
      if words_match_tag(words, cat_value)
        main_matches = true
      end
      
      # Check if any subcategory matches
      subcategories = []
      value.subcats.each do |sub_name, sub_value|
        if words_match_tag(words, sub_value)
          main_matches = true
          subcategories << sub_name
        end
      end
      
      # Add this category and subcategories if neccessary
      if main_matches
        matched_categories[cat_name.to_sym] = subcategories
      end
    end
    
    matched_categories
  end
  
  # This method takes an app and returns the
  #  app with a list of tags (ex: Disney, trucks)
  def self.parse_for_app_interests(app)
    
  end
  
end