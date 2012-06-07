class Version
  include MongoMapper::EmbeddedDocument

  key :num,       String
  key :date,      Time
  key :desc,      String
  key :ratings,   Array
  key :reviews,   Array
  belongs_to :app
  timestamps!

end
