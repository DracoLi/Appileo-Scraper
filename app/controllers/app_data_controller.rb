require 'cgi'

class AppDataController < ApplicationController
  
  def top_data
    
    a = AppData.all.uniq.first
    #puts a.app_id
    #puts a.bundle_id
    
    message = 'select apps successfully'
    if a.valid?
      message = a.errors
    end
    render :json => { :success    => true,
                      :message    => message, 
                      :apps_data  => a.as_json
                    }
  end
  
  def new_data
    render :text => "new"
  end
  
  def lookup_data
    
    params = request.query_parameters
    
    search_keys = ['name', 'a_id', 'p_id', 'country', 'device', 'min_price', 'max_price']
    query = {}
    
    search_keys.each do |key|
      param = params[key]
      
      next unless param
      
      puts 'key %s, param %s' % [key, param]
      
      case key
      when 'a_id', 'p_id'
        query[key] = params[key].to_f
      when 'name'
        query[key] = /#{params[key]}/
      when 'min_price'
        query['price'] = {} unless query['price']
        query['price'][:$gt] = param[key].to_f
      when 'max_price'
        query['price'] = {} unless query['price']
        query['price'][:$lt] = param[key].to_f
      else
        query[key] = params[key]
      end
    end
    
    puts query
    
    #render :text => request.query_parameters
    render :json => AppData.search(query).all.as_json
  end
  
end
