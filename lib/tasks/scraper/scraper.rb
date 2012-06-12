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

  # Creates of update an object, which is of type model class,
  # with the provided list of attributes.
  # The method returns an array of two items, the first is a
  # boolean if the object requires future save to the database
  # and the second is the object itself in order to allow to
  # assign to a parent object later
  def self.create_or_update_object(object, model, attributes)

    if object == nil
      # If object is nil, create a new one
      object = model.new(attributes)
      puts model.name + ": Data needs to be created"
      return [true, object]
    else
    # If object exists already, check if there are differences
    # in the values provided
      hash_diff_keys =  attributes.diff(object.attributes).keys
      hash_diff_keys.each do |key|
        if attributes.keys.include?(key)
          # If one of the keys needed to be updated,
          # update the whole structure and mark for saving
          object.attributes = attributes
          puts model.name + ": Data needs to be updated"
          return [true, object]
        end
      end
    end
    return [false, object]
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
    save_needed, app.publisher = create_or_update_object(app.publisher, Publisher, attributes)
    return save_needed
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
                  'icon512' => data['artworkUrl512'] }

    # Return boolean marking if object was created or updated and
    # needs to be saved, written, to the db afterwards
    save_needed, app.pics = create_or_update_object(app.pics, Pics, attributes)
    return save_needed
  end
  
  # Method that processes the Reviews Embedded Document
  # inside Store inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.reviews_data_processor(app, store_index, store_reviews)
    # Create hash with all values to be checked
    # Keys have to be in 'string' format instead of :string
    # in order to be able to match the keys to the ones
    # returned in the data using 'diff' on the hashes
    
    # If there are reviews, get the latest review datetime
    # in order to make sure to insert only the ones that were
    # recorded afterwards 
    last_date = nil
    if !app.store[store_index].review.empty?
      app.store[store_index].review.each do |review|
        last_date = review.date if (last_date == nil || review.date > last_date)
      end
    end
    
    # Keep flag if save is needed
    save_needed = false
    
    # Iterate through all reviews
    store_reviews.each do |review|
      # TODO: make sure there will be no duplicates in reviews
      if last_date == nil || Date.parse(review[:date]) > last_date 
        # If review was recorded later then the latest review,
        # add it to the database, otherwise ignore
        attributes = {:body => review[:body],
                      :subject => review[:subject],
                      :rating => review[:rating],
                      :author => review[:author],
                      :version => review[:version],
                      :date => review[:date] }
                      
        puts Review.name + ": Data needs to be created"
        app.store[store_index].review << Review.new(attributes)
        save_needed = true
      end
    end     
    
    return save_needed
    
  end
  
  # Method that processes the Price Embedded Document
  # inside Store inside AppData 'app' with the data provided
  # Returns true if changes were made and later save is needed
  # false otherwise
  def self.price_data_processor(app, store_index, data)
    # Create hash with all values to be checked
    # Keys have to be in 'string' format instead of :string
    # in order to be able to match the keys to the ones
    # returned in the data using 'diff' on the hashes
    
    attributes = {'amount' => data['price'],
                  'currency' => data['currency'] }

    # Return boolean marking if object was created or updated and
    # needs to be saved, written, to the db afterwards
    save_needed, app.store[store_index].price = 
      create_or_update_object(app.store[store_index].price, Price, attributes)
    
    return save_needed
  end

  def self.store_processor(app, store_index, country, data, store_reviews)
  
    attributes = {:country => country,
                  :release_date => data['releaseDate'],
                  :link => data['trackViewUrl'],
                  :publisher_link => data['artistViewUrl'],
                  :total_ratings_count => data['userRatingCount'],
                  :total_average_rating => data['averageUserRating'],
                  :current_ratings_count => data['userRatingCountForCurrentVersion'],
                  :current_average_rating => data['averageUserRatingForCurrentVersion'] }

    if store_index == nil
      puts Store.name + ": Data needs to be created"
      app.store << Store.new(attributes)
      save_needed_store = true
      
      # Get the store index after creation
      app.store.each_index do |i|
        store_index = i if app.store[i].country == country
      end
    else
      # If object exists already, check if there are differences
      # in the values provided
      save_needed_store, app.store[store_index] =
        create_or_update_object(app.store[store_index], Store, attributes)
    end
    
    save_needed_price = price_data_processor(app, store_index, data)
    save_needed_reviews = reviews_data_processor(app, store_index, store_reviews)
    
    return save_needed_store || save_needed_price || save_needed_reviews
    
  end

  # Processing the data for the whole AppData Document Model
  # and its embedded models. Save only happens after the whole
  # model has been processed and needs to be save because of
  # creation of an object or update of attributes
  def self.app_processor(app, data)

    # Run all the processors on the Document and its EmbeddedDocuments
    # check if any of them returned a flag that changes happended
    save_needed_app = app_data_processor(app, data)
    save_needed_publisher = publisher_data_processor(app, data)
    save_needed_pics = pics_data_processor(app, data)

    # If any of the data processors returned true tell that needs to be saved
    return save_needed_app || save_needed_publisher || save_needed_pics

  end

  def self.scrape_apps()

    new_apps = ScraperWorker.scrape_all
    # If scaper returned successfully, load all apps to memory
    # This allows comparisson without hitting the DB for every app
    # NOTE: If data goes above machine RAM, work has to be done in chunks
    # TODO: apps = AppData.all

    # Iterate on all apps that were retrieved
    (new_apps).each do |app_id, app_data|

      is_save_needed = false

      stores_result = app_data[:result]
      stores_reviews = app_data[:reviews]
      raise "ERROR: number of countries does not match in results and reviews" \
        unless Integer(stores_result.length) == Integer(stores_reviews.length)       

      # Run app specific processing that is not related to stores
      puts "\nProcessing app id: " + app_id

      # Try to get data from collection, otherwise create new one
      # note: this won't validate or save to database yet
      app = AppData.find_or_initialize_by_a_id(Float(app_id))

        
      # Get first set of values from the 0 store since all
      # stores hold the same generic values
      data = stores_result.values[0]

      is_save_needed = true if app_processor(app, data)

      # Iterate on all stores that were scraped
      (stores_result).each do |country, store_data|
        puts "Processing store: " + country
        raise "ERROR: app_id does not equal trackId, check mapping." \
        unless Integer(app_id) == Integer(store_data['trackId'])
        
        # Find reviews from the same country
        store_reviews = stores_reviews[country]

        # Check if store exists, and if so if found. Otherwise pass nil
        # in order to create a new store for the country
        store_index = nil
        if !app.store.empty?
          # Searching array of stores in order not to hit the database again
          # since queries on a document always have to hold the root.
          # If database queries wanted, then it can be replaced with
          # A.all(:conditions => {'b.c.name' => 'appileo'}) structure
          # and raise "ERROR: multiple entries for the same countries
          # were found. unless store.count == 1 can be added as a check
          app.store.each_index do |i|
            store_index = i if app.store[i].country == country
          end
        end
        is_save_needed = true if store_processor(app, store_index, country, store_data, store_reviews)
      end

      if is_save_needed
        # If any of the data processors returned true data needs to be saved
        app.save
        puts AppData.name + ": DATA SAVED"
      else
        puts AppData.name + ": Data up to date"
      end
    end
  end
end

Scraper.scrape_apps
