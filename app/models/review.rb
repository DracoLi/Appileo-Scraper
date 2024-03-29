# NOTE
# Review cannot be an Embedded MongoMapper Document since the amount of reviews
# can be over 650. If the number of reviews goes above this number, the Embedded
# Document reference will blow up and a Stack Level is Too Deep exception will
# be thrown. This might be fixed in future versions of Rails or MongoMapper.
# This is a well known issue, #265.
# See: https://github.com/jnunemaker/mongomapper/pull/265

class Review
  include MongoMapper::Document
  # NOTE: Be careful not to override id or _id keys
  # that are pregenerated by Rails and result with
  #unexpected behaviour such as stack errors
  
  key :version,   String
  key :rating,    Integer
  key :author,    String
  key :date,      Date
  key :subject,   String
  key :body,      String
  
  belongs_to :app_data
  
  timestamps!

end
