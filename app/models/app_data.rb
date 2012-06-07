class AppData
  include MongoMapper::Document

  # app_id is float to avoid overflows
  key :app_id,        Float,    :required => true 
  key :bundle_id,     String,   :required => true
  key :name,          String,   :required => true
  key :title,         String,   :required => true
  key :link,          String,   :required => true
  key :summary,       String,   :required => true
  key :summary_html,  String,   :required => true
  key :website,       String,   :required => true
  key :support,       String,   :required => true
  key :devices,       Array,    :required => true
  key :release,       Time,     :required => true
  key :advisory,      String,   :required => true
  key :game_center,   Boolean,  :required => true
  key :size,          Integer,  :required => true
  key :lang,          Array,    :required => true
  key :region,        String,   :required => true
  
  one :legal
  one :publisher
  one :price
  one :pics 
  many :versions
  
  timestamps!

end
