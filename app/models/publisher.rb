class Publisher
  include MongoMapper::EmbeddedDocument

  key :name,      String
  key :company,   String
  key :id,        Integer
  key :link,      String
  belongs_to :app
  timestamps!

end
