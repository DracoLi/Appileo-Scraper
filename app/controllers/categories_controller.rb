class CategoriesController < ApplicationController
  
  CATEGORY_FILE = \
    "#{Rails.root}/app/assets/data/category_tags.json"
    
  def index
    @all_categories
    File.open(CATEGORY_FILE, 'r') do |f|
      @all_categories = ActiveSupport::JSON.decode f.read 
    end
  end
  
  def update
    @ori_name = params[:original_name]
    @cat_name = params[:name]
    matches = params[:matches].split(",")
    sub_names = params[:sub_names].split(",")
    
    cat_value = { matches: matches, subcats: {} }
    sub_names.each do |name|
      sub_name = to_camel name
      sub_matches = params["#{sub_name}_matches"].split(",")
      cat_value[:subcats][name] = { matches: sub_matches }
    end
    
    # Add/replace this category with the one on file
    all_categories = get_from_file CATEGORY_FILE
    all_categories.delete @ori_name
    all_categories[@cat_name] = cat_value
    save_to_file CATEGORY_FILE, all_categories
  end
  
  def destroy
    @cat_name = params[:name]
    @ori_name = params[:original_name]
    all_categories = get_from_file CATEGORY_FILE
    all_categories.delete @ori_name
    save_to_file CATEGORY_FILE, all_categories
  end
  
  def raw
    content = get_from_file CATEGORY_FILE
    render json: content
  end
  
end
