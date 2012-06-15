require 'cgi'

class AppDataController < ApplicationController
  
  def top_data
    
    device = params[:device]
    category = params[:category]
    country = params[:country]
    
    # Format the rank we want to get
    rank = "rank.top_%s_apps_%s" % [category, device]
    
    logger.info(rank)
    
    apps = AppData.where(
      {'store' => 
        {'$elemMatch' => 
          {'country' => country, 
            rank => {:$gt => 0}
          }
        }
      }).all
      
    # .sort( 'store.' + rank )
    
    render :json => {
      :success    => true,
      :message    => "Success",
      :apps_data  => apps.as_json
    }
    
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
    
    render :json => AppData.search(query).limit(100).all.as_json
  end
  
end
