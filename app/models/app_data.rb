class AppData
  include MongoMapper::Document
  # NOTE: Be careful not to override id or _id keys
  # that are pregenerated by Rails and result with
  #unexpected behaviour such as stack errors
  
  scope :search,      lambda { |query| where(query) }
  
  # App specific data, duplicated over each store instance of the app
  # app_id is float to avoid overflows
  key :a_id,          Float,    :required => true 
  key :bundle_id,     String,   :required => true
  key :name,          String,   :required => true
  key :summary,       String,   :required => true
  key :devices,        Array,    :required => true
  key :advisory,      String,   :required => true
  key :game_center,   Boolean
  key :size,          Integer,  :required => true
  key :lang,          Array,    :required => true
  key :version,       String,   :required => true
  
  # Categorization attributes - Used by ScraperCategorizer task
  key :category,    String
  key :sub_category, String
  key :interests, Array
  
  # Data below kept at the Document level to allow sorting and filtering
  
  # Store specific data  
  key :country,                   String,   :required => true
  key :release_date,              Time,     :required => true
  key :link,                      String,   :required => true
  
  key :total_ratings_count,       Integer
  key :total_average_rating,      Float
  key :current_ratings_count,     Integer
  key :current_average_rating,    Float
  
  # Weight calculated from scrapper runner
  key :popularity_weight,         Float
  
  # Ranks data
  key :new_apps,                  Integer
  key :new_free_apps,             Integer
  key :new_paid_apps,             Integer

  key :top_free_apps_iphone,      Integer
  key :top_paid_apps_iphone,      Integer
  key :top_gros_apps_iphone,      Integer
  
  key :top_free_apps_ipad,        Integer
  key :top_paid_apps_ipad,        Integer
  key :top_gros_apps_ipad,        Integer  

  # Price Data
  key :amount,      Float,    :required => true
  key :currency,    String,   :required => true
  
  # Publisher Data
  key :pub_id,        Float,    :required => true
  key :pub_name,      String,     :required => true
  key :pub_company,   String,     :required => true
  key :pub_link,              String
 
  # Pics
  key :pic_iphone,      Array
  key :pic_ipad,        Array
  key :pic_icon60,      String,  :required => true
  key :pic_icon100,     String,  :required => true
  key :pic_icon512,     String,  :required => true
  
  # Reviews
  # Note: Review documents are linked to AppData in order to support a large
  # amount of document without raising a stack level too deep exception
  # that results because of the callback methods that are pilling up.
  many :review
  
  timestamps!
  
  # Validating game_center boolean flag since required false
  # acts according to Object#blank and will not work
  validates_inclusion_of :game_center, :in => [true, false]
  
  def self.create_indexes
    # Create indexes when server loading the mongo.rb initializer
    
    # variables that end with _id are already indexes by default
    self.ensure_index(:name)
    
    self.ensure_index([[:popularity_weight, -1]])
    self.ensure_index([[:category, 1], [:sub_category, 1]])
    self.ensure_index(:sub_category)
    
    self.ensure_index(:interests)
    self.ensure_index(:country)
    self.ensure_index(:release_date)
    self.ensure_index([[:total_ratings_count, -1]])
    self.ensure_index([[:total_average_rating, -1]])
    self.ensure_index([[:current_ratings_count, -1]])
    self.ensure_index([[:current_average_rating, -1]])
    
    self.ensure_index(:new_apps)
    self.ensure_index(:new_free_apps)
    self.ensure_index(:new_paid_apps)
    self.ensure_index(:top_free_apps_iphone)
    self.ensure_index(:top_paid_apps_iphone)
    self.ensure_index(:top_gros_apps_iphone)
    self.ensure_index(:top_free_apps_ipad)
    self.ensure_index(:top_paid_apps_ipad)
    self.ensure_index(:top_gros_apps_ipad)

    self.ensure_index(:amount)
    
    self.ensure_index(:pub_name)
  end

end
