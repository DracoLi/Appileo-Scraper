class Price
  include MongoMapper::EmbeddedDocument

  key :amount,      Float
  key :currency,    String
  belongs_to :app
  timestamps!

end
