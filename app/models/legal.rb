class Legal
  include MongoMapper::EmbeddedDocument
  
  key :rights,      String
  key :agreement,   String
  belongs_to :app
  timestamps! 
  
end
