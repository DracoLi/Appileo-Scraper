require 'cgi'

class AppDataController < ApplicationController
  
  def all_data
    limit_num = get_limit
    render json: AppData.limit(limit_num).all
  end
  
  # API call /top/:country/:device/:category_top handler
  # returns the list of apps that match the top criteria for any category
  def top_data
    
    # Parse parameters
    device = params[:device]
    category = params[:category_top]
    
    # Format the rank we want to search on
    rank = "top_%s_apps_%s" % [category, device]
    
    # Get query parameters and add the rank
    query = get_query.merge!({rank => {:$gt => 0}})

    # Get list of fields to return
    fields = get_fields
    
    # Get list of fields to remove
    without = get_without_fields

    # Check if sorting method is specified
    sort_field = get_sorting(rank)
    
    # If the limit is specified set it otherwise default to 100
    limit_num = get_limit
    
    # Create mongo query.
    # Select based on store where both criteria match:
    # => country is the specified one
    # => rank is greater than 0
    apps = AppData.where(query)
                  .sort(sort_field)
                  .fields(fields)
                  .limit(limit_num)
                  .all
    
    # Apply interests weighting if interests exist              
    apps = weight_interests(apps, request.query_parameters['interests'])
    
    # Return result as json
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json(:only => fields, :except => without)
    }
    
  end
  
  # API call /new/:country(/:category_new) handler
  # returns the list of apps that match the new criteria for any category
  def new_data
    
    # Parse parameters
    rank = 'new'
    
    # Format the rank we want to search on
    if (params[:category_new])
      rank += "_%s_apps" % params[:category_new]
    else
      rank += "_apps"
    end
    
    # Get query parameters and add the rank
    query = get_query.merge!({rank => {:$gt => 0}})

    # Get list of fields to return
    fields = get_fields
    
    # Get list of fields to remove
    without = get_without_fields

    # Check if sorting method is specified
    sort_field = get_sorting(rank)
    
    # If the limit is specified set it otherwise default to 100
    limit_num = get_limit
    
    # Create mongo query.
    # Select based on store where both criteria match:
    # => country is the specified one
    # => rank is greater than 0
    apps = AppData.where(query)
                  .sort(sort_field)
                  .fields(fields)
                  .limit(limit_num)
                  .all
                  
    # Apply interests weighting if interests exist              
    apps = weight_interests(apps, request.query_parameters['interests'])
    
    # Return result as json
    render :json => apps.as_json(:only => fields, :except => without)
    
  end
  
  # API call /lookup handler
  # Return list of apps that match the specified criteria
  def lookup_data
    
    # Note: At least one query parameter is required
    render :json => {
      :success    => false,
      :message    => "No query parameters",
      :apps_data  => []
    } unless request.query_parameters
    
    # Get query parameters
    query = get_query
    
    # Get list of fields to return
    fields = get_fields
    
    # Get list of fields to remove
    without = get_without_fields

    # Check if sorting method is specified
    sort_field = get_sorting('popularity_weight')
    
    # If the limit is specified set it otherwise default to 100
    limit_num = get_limit

    apps = AppData.where(query)
                  .sort(sort_field)
                  .fields(fields)
                  .limit(limit_num)
                  .all
                  
    # Apply interests weighting if interests exist              
    apps = weight_interests(apps, request.query_parameters['interests'])
                  
    # Return result as json
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json(:only => fields, :except => without)
    }
    
  end
  
  def reviews_data
    # Get the app with the requested country and app id
    
    apps = AppData.where({
      :country => params[:country],
      :a_id => Float(params[:a_id])
      }
    )
    
    if (apps == nil || apps.count == 0)
      # If the app was not found
      render :json => {
        :success    => false,
        :message    => "App data not found",
        :apps_data  => []
      }
    else
      # Return result as json
      render :json => {
        :success    => true,
        :message    => "Success",
        :reviews_data  => apps.first.review.as_json()
      }
    end
  end
  
  ##### Helper methods #####
  
  # Get the query to filter results from the model.
  # This is generic for every API call
  def get_query
    
    # Get query parameters passed
    query_params = request.query_parameters
    
    # Initialize query with country from route
    query = {'country' => params[:country]}
    
    # Allowed search terms, only these keys are searchable 
    search_keys = ['name', 'a_id', 'pub_id', 'device', 'min_price', 'max_price',
                   'pub_name', 'min_app_rating', 'max_app_rating',
                   'category', 'sub_category', 'interests_only']
                   
    # Iterate through the keys, determine if the params match the key and if so 
    # add a condition to the query
    search_keys.each do |key|
      param = query_params[key]
      
      # Make sure the parameter is defined 
      next unless param
      
      #logger.info('key %s, param %s' % [key, param])
      
      # handlers for different keys
      case key
      when 'a_id', 'pub_id'
        # IDs are floats so convert
        query[key] = query_params[key].to_f
      when 'name', 'pub_name'
        # Do regex match on names so you can match substring
        query[key] = /#{query_params[key]}/
      when 'min_price'
        query['amount'] = {} unless query['amount']
        query['amount'][:$gte] = param.to_f
      when 'max_price'
        query['amount'] = {} unless query['amount']
        query['amount'][:$lte] = param.to_f
      when 'min_app_rating'
        query['total_average_rating'] = {} unless query['total_average_rating']
        query['total_average_rating'][:$gte] = param.to_f
      when 'max_app_rating'
        query['total_average_rating'] = {} unless query['total_average_rating']
        query['total_average_rating'][:$lte] = param.to_f
      when 'interests_only'
        interest_query = []
        param.split(',').each do |interest|
          interest_query << {:interests => interest}
        end
        # And filter only the apps that have either one of the interests
        query[:$and] = [{:$or => interest_query}]
      else
        # Deals with all the parameters that are specified and match with
        # the model attributes
        query[key] = param
      end
    end
    
    return query
  end

  # Go over all passed fields and keep the ones that actually exist in model  
  def get_fields
    # Initialize fields to return with empty array in order to include all
    fields = []
    query_params = request.query_parameters
    if query_params.has_key? 'fields'
      fields = query_params['fields'].downcase.split(',')
      delete_fields = []
      fields.each do |field|
        delete_fields << field unless (AppData.column_names.include?(field) || (field == 'review'))
      end
    end
    return fields - delete_fields
  end
  
  # Go over all passed fields and remove the ones we don't want
  def get_without_fields
    # Initialize fields to return with empty array in order to include all
    fields = []
    query_params = request.query_parameters
    if query_params.has_key? 'without'
      fields = query_params['without'].downcase.split(',')
      fields.each do |field|
        fields.delete(field) if !AppData.column_names.include? field
      end
    end
    
    return fields
  end

  # Check if sorting method is specified
  # Note: the sort_field has to match the model exactly  
  def get_sorting (default_sort_key)
    
    # Allowed sort fields, can sort by only these fields (are indexed) 
    sort_keys = ['name', 'a_id', 'pub_id' , 'popularity_weight', 'category', 
                   'sub_category', 'interests', 'release_date', 
                   'total_ratings_count', 'total_average_rating',
                   'current_ratings_count', 'current_average_rating',
                   'new_apps', 'new_free_apps', 'new_paid_apps', 
                   'top_free_apps_iphone', 'top_paid_apps_iphone',
                   'top_gros_apps_iphone', 'top_free_apps_ipad',
                   'top_paid_apps_ipad', 'top_gros_apps_ipad', 'amount',
                   'pub_name']
    
    # Get the sort_by parameter if it exists, otherwise use the default
    sort_param = request.query_parameters['sort_by'] || default_sort_key
    
    # Make sure the sort parameter is in our allowed list 
    sort_key = sort_param if sort_keys.include?sort_param  
    return sort_key
    
  end
  
  # Set the limit of results returned. If not specified limit to 100 
  def get_limit
    return request.query_parameters['limit'] || 100
  end
  
  def weight_interests(apps, interests)
  
    # Get gamma value from constants file (included in the assets pipeline)
    $GAMMA_INTERESTS = ScraperConstants.getGammaInteretsts()
    
    # If no interests provided, don't run anything and return the apps
    if interests == nil
      return apps
    end
    
    # Transform interests to array
    interests = interests.downcase.split(',')
    
    # Run over all the apps that were retrieved
    # and give points if interest found in them
    apps.each do |app|
      # Find intersection between the app interests and the ones wanted
      # the length of the intersection is the score of the matches
      app['interests_matches'] = (app.interests & interests).length
      
      # Create the weighted average of each app according to popularity
      # of the app and the interests match. Popularity is assumed to be
      # a percentage between 0 and 1 since it's a calculated weight as well.
      # Interests length is greater than zero because otherwise we would
      # have returned at the beginning of the method.
      # Note: GAMMA_INTERESTS can be adjusted in the scraper_constants.rb file
      app['interests_weight'] = $GAMMA_INTERESTS *
                                app.popularity_weight.to_f +
                                (1-$GAMMA_INTERESTS) *
                                app['interests_matches'] / interests.length
    end
    
    # Return apps sorted in descending order by the interests weight
    return apps.sort_by{|e| -e['interests_weight']}
    
  end
  
end
