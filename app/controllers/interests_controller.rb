class InterestsController < ApplicationController
  
  INTERESTS_FILE = \
    "#{Rails.root}/app/assets/data/interest_tags.json"
    
  def index
    @all_interests
    File.open(INTERESTS_FILE, 'r') do |f|
      @all_interests = ActiveSupport::JSON.decode f.read 
    end
  end

  def update
    # Construct on interests content from form
    all_interests = Hash.new
    int_names = params[:int_names].split(",")
    int_names.each do |interest|
      one_interest = Hash.new
      int_name = to_camel interest
      int_matches = params["#{int_name}_matches"].split(",")
      int_gender = params["#{int_name}_gender"]
      one_interest[:matches] = int_matches
      one_interest[:gender] = int_gender
      all_interests[interest.to_sym] = one_interest
    end
    
    # Replace this interests with the one on file
    save_to_file INTERESTS_FILE, all_interests
  end
  
  def raw
    content = get_from_file INTERESTS_FILE
    render json: content
  end
  
end
