require 'cgi'

class AppDataController < ApplicationController
  
  def top_data
    render :text => "top"
  end
  
  def new_data
    render :text => "new"
  end
  
  def lookup_data
    render :text => request.query_parameters
  end
  
end
