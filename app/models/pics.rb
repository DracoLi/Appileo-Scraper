class Pics
  include MongoMapper::EmbeddedDocument

  key :iPhone,    Array
  key :iPad,      Array
  key :icons,     Array
  belongs_to :app
  timestamps!

end
