require 'scraper_worker.rb'

module Scraper

  include ScraperWorker
  
  # Method that processes the AppData Document with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.app_data_processor(app, data)  
    # Flag to mark if object was created or updated and
    # needs to be saved, written, to the db afterwards
    save_needed = false
  
    # Handle special case for supported devices if 'all'
    if (data['supportedDevices'] - ['all'] == [])
      supported_devices = ['iphone', 'ipad']
    else
      supported_devices = data['supportedDevices']
    end
    
    # Create hash with all values to be checked
    attributes = {:a_id => data['trackId'], 
                  :bundle_id => data['bundleId'],
                  :name => data['trackName'],
                  :summary => data['description'],
                  :devices => supported_devices,
                  :advisory => data['contentAdvisoryRating'],
                  :game_center => data['isGameCenterEnabled'],
                  :size => data['fileSizeBytes'],
                  :lang => data['languageCodesISO2A'],
                  :version => data['version'] }
    
    app.attributes = attributes
    
    if app.invalid?
      # Check if app_data attributes are valid otherwise inform about errors
      puts AppData.name + ": Error validating data"
      app.errors.each { |error, message| puts "-> #{error}: #{message}" }
    else
      # If validation passed, check if needs to save
      if app.changed?
        save_needed = true
        puts AppData.name + ": Data needs to be updated"
      end
    end
    
    return save_needed  
  end
  
  def self.create_or_update_object(object, model, attributes)
    if object == nil
      object = model.new(attributes)
      puts model.name + ": Data needs to be created"
      return true
    else
      hash_diff_keys =  attributes.diff(object.attributes).keys
      hash_diff_keys.each do |key|
        if attributes.keys.include?(key)
          # If one of the keys needed to be updated,
          # update the whole structure and mark for saving
          object.attributes = attributes
          puts model.name + ": Data needs to be updated"
          return true
        end
      end
    end
    
    return false
  end
  
  # Method that processes the Publisher Embedded Document
  # inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.publisher_data_processor(app, data)  
    # Create hash with all values to be checked
    # Keys have to be in 'string' format instead of :string
    # in order to be able to match the keys to the ones
    # returned in the data using 'diff' on the hashes
    attributes = {'p_id' => Float(data['artistId']),
                  'name' => data['artistName'], 
                  'company' => data['sellerName'] }
    
    # Return boolean marking if object was created or updated and
    # needs to be saved, written, to the db afterwards
    return create_or_update_object(app.publisher, Publisher, attributes)
  end
  
  # Method that processes the Pics Embedded Document
  # inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.pics_data_processor(app, data)  
    # Create hash with all values to be checked
    # Keys have to be in 'string' format instead of :string
    # in order to be able to match the keys to the ones
    # returned in the data using 'diff' on the hashes
    attributes = {'iphone' => data['screenshotUrls'],
                  'ipad' => data['ipadScreenshotUrls'], 
                  'icon60' => data['artworkUrl60'],
                  'icon100' => data['artworkUrl100'],
                  'icon512' => data['artworkUrl512']}
    
    # Return boolean marking if object was created or updated and
    # needs to be saved, written, to the db afterwards
    return create_or_update_object(app.pics, Pics, attributes)
  end
  
  def self.store_processor(app, store, country, data)
    # TODO: Add logic for store specific
    if store == nil
      puts Store.name + ": Data needs to be created"
      
      attributes = { :country => country,
                     :release_date => data['releaseDate'],
                     :link => data['trackViewUrl'],
                     :publisher_link => data['artistViewUrl'],
                     :total_ratings_count => data['userRatingCount'],
                     :total_average_rating => data['averageUserRating'],
                     :current_ratings_count => data['userRatingCountForCurrentVersion'],
                     :current_average_rating => data['averageUserRatingForCurrentVersion'] }
       
      app.store << store if store = Store.new(attributes)
      app.save
    end
  end
  
  # Processing the data for the whole AppData Document Model
  # and its embedded models. Save only happens after the whole
  # model has been processed and needs to be save because of
  # creation of an object or update of attributes
  def self.app_processor(app, data)
    
    # Run all the processors on the Document and its EmbeddedDocuments
    # check if any of them returned a flag that changes happended
    if app_data_processor(app, data) || \
       publisher_data_processor(app, data) || \
       pics_data_processor(app, data)
       # If any of the data processors returned true data needs to be saved
      app.save
      puts AppData.name + ": DATA SAVED"
    else
      puts AppData.name + ": Data up to date"
    end
    
  end

  def self.scrape_apps()
  
    new_apps = ScraperWorker.scrape_all
    # If scaper returned successfully, load all apps to memory
    # This allows comparisson without hitting the DB for every app
    # NOTE: If data goes above machine RAM, work has to be done in chunks
    # TODO: apps = AppData.all
    
    # Iterate on all apps that were retrieved
    (new_apps).each do |app_id, app_data|
      
      stores_result = app_data[:result]
      stores_reviews = app_data[:reviews]
      
      # Run app specific processing that is not related to stores
      puts "\nProcessing app id: " + app_id
      
      # Try to get data from collection, otherwise create new one
      # note: this won't validate or save to database yet      
      app = AppData.find_or_initialize_by_a_id(Float(app_id))
      # Get first set of values from the 0 store since all
      # stores hold the same generic values
      data = stores_result.values[0]
      
      app_processor(app, data)
      
      # Iterate on all stores that were scraped
      (stores_result).each do |country, store_data|
        puts "Processing store: " + country
        raise "ERROR: app_id does not equal trackId, check mapping." \
              unless Integer(app_id) == Integer(store_data['trackId'])
        if app.store.empty?
          puts "EMPTY STORE"
          store_processor(app, app.store, country, store_data)
        else
          puts "NON EMPTY STORE"
          store = nil
          # Searching array of stores in order not to hit the database again
          # since queries on a document always have to hold the root.
          # If database queries wanted, then it can be replaced with 
          # A.all(:conditions => {'b.c.name' => 'appileo'}) structure
          # and raise "ERROR: multiple entries for the same countries
          # were found. unless store.count == 1 can be added as a check
          app.store.each { |s| store = s if s.country == country }
          store_processor(app, store, country, store_data)
        end
      end
    end
  end
end

Scraper.scrape_apps
