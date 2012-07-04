require 'cgi'

class AppDataController < ApplicationController
  
  # API call /top/:country/:device/:category_top handler
  # returns the list of apps that match the top criteria for any category
  def top_data
    
    # Parse parameters
    device = params[:device]
    category = params[:category_top]
    country = params[:country]
    
    # Set or get the limit parameter
    limit_num = params[:limit] || 100
    
    # Format the rank we want to search on
    rank = "top_%s_apps_%s" % [category, device]
    
    logger.info(rank)
    
    # Create mongo query.
    # Select based on store where both criteria match:
    # => country is the specified one
    # => rank is greater than 0
    apps = AppData.where( {'country' => country, rank => {:$gt => 0} })
                  .sort(rank)
                  .limit(limit_num)
                  .all
    
    # Return result as json
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json
    }
    
  end
  
  # API call /new/:country(/:category_new) handler
  # returns the list of apps that match the new criteria for any category
  def new_data
    
    # Parse parameters
    country = params[:country]
    rank = 'new'
    
    # Set or get the limit parameter
    limit_num = params[:limit] || 100
    
    # Format the rank we want to search on
    if defined?(params[:category_new])
      rank += "_%s_apps" % params[:category_new]
    else
      rank += "_apps"
    end
    
    logger.info(rank)
    
    # Create mongo query.
    # Select based on store where both criteria match:
    # => country is the specified one
    # => rank is greater than 0
    apps = AppData.where({'country' => country, rank => {:$gt => 0}})
                  .sort(rank)
                  .limit(limit_num)
                  .all
    
    # Return result as json
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json
    }
    
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
    query_params = request.query_parameters
    # Allowed search terms, only these keys are searchable 
    search_keys = ['name', 'a_id', 'pub_id', 'device', 'min_price', 'max_price',
                   'pub_name', 'min_app_rating', 'max_app_rating',
                   'category', 'sub_category', 'interests']
    
    # Initialize query with country from route
    query = {'country' => params[:country]}
    
    # Initialize fields to return with empty array in order to include all
    fields = []
    # Go over all passed fields and keep the ones that actually exist in model
    if query_params.has_key? 'fields'
      fields = query_params['fields'].downcase.split(',')
      fields.each do |field|
        fields.delete(field) if !AppData.column_names.include? field
      end
    end
    # At this point we have the correct list of fields to return

    # Iterate through the keys, determine if the params match the key and if so 
    # add a condition to the query
    search_keys.each do |key|
      param = query_params[key]
      
      # Make sure the parameter is defined 
      next unless param
      
      logger.info('key %s, param %s' % [key, param])
      
      # handlers for different keys
      case key
      when 'a_id', 'pub_id'
        # IDs are floats so convert
        query[key] = query_params[key].to_f
      when 'name', 'pub_name'
        # Do regex match on names so you can match substring
        query[key] = /#{query_params[key]}/
      when 'min_price'
        query['price'] = {} unless query['price']
        query['price'][:$gt] = param[key].to_f
      when 'max_price'
        query['price'] = {} unless query['price']
        query['price'][:$lt] = param[key].to_f
      when 'min_app_rating'
        query['total_average_rating'] = {} unless query['total_average_rating']
        query['total_average_rating'][:$gt] = param[key].to_f
      when 'max_app_rating'
        query['total_average_rating'] = {} unless query['total_average_rating']
        query['total_average_rating'][:$lt] = param[key].to_f
      when 'interests'
        interest_query = []
        param.split(',').each do |interest|
          interest_query << {:interest => interest}
        end
        query[:$and] = interest_query
      else
        # Deals with all the parameters that are specified and match with
        # the model attributes
        query[key] = query_params[key]
      end
    end
    
    # Check if sorting method is specified
    # Note: the sort_field has to match the model exactly
    sort_field = query_params['sort_by'] || 'a_id'
    
    # If the limit is specified set it otherwise default to 100
    limit_num = query_params['limit'] || 100
    
    logger.info(query)
    logger.info(sort_field)
    logger.info(limit_num)
    
    apps = AppData.search(query)
                  .sort(sort_field)
                  .fields(fields)
                  .limit(limit_num)
                  .all
                  
    # Return result as json
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json(:only => fields)
    }
    
  end
  
end
