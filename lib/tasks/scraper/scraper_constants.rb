module ScraperConstants

  ### Debug info
  
  # Define the maximum rating from the app store for the categorization
  MAX_RATING = 5
  
  # Define the weight gamma variable for the weighted average between the 
  # total number of ratings to the total average rating.
  # Weighted average by percentages equals to:
  # GAMMA     * TOTAL_RATINGS_COUNT / MAX_RATINGS_COUNT +
  # (1-GAMMA) * TOTAL_AVERAGE_RATING / MAX_RATING
  # Note: Gamma has to be between zero and 1 inclusive
  GAMMA_RATINGS = 0.8
  
  # Define the weight gamma variable for the weighted average between the 
  # popularity metric (# of ratings/ave rating) to interests matches
  # Weighted average by percentages equals to:
  # GAMMA     * populrity +
  # (1-GAMMA) * number of interest matches
  # Note: Gamma has to be between zero and 1 inclusive
  GAMMA_INTERESTS = 0.5
  
  
  
  
    # Path to the categories and interest files
  CATEGORY_FILE = "#{Rails.root}/app/assets/data/category_tags.json"
  INTEREST_FILE = "#{Rails.root}/app/assets/data/interest_tags.json"
  
  # Regex to split array
  SCAN_REGEX          = /[\w-]+/
  # Part of regex that matches a space and a word.
  WORD_SPACE_REGEX    = /(\s{1,}\w{1,})/
  
  # key name for the keywords to match
  KEYWORD_MATCH       = 'matches'
  # key name for the minimum number of required tags
  KEYWORD_MIN_TAGS    = 'min_tags'
  # Multiplier for when a keyword match is found on the title
  TITLE_MATCH_MULT    = 3
  # Minimum number of matches before tagging
  KEY_MIN_MATCHES     = 1
  
  # sub categories key name
  SUB_CAT       = 'subcats'
  
  # sub category parent
  SUB_CAT_PARENT  = 'parent'
  
  
  
  # Enable and disable debugging
  DEBUG           = true
  # Limit on how many pages of apps to scrape from itunes. 
  # NOTE: Only works if DEBUG enabled.
  DEBUG_MAX_PAGES = 1
  # Limit on number of apps to be scraped, including itunes lookup and reviews.
  # NOTE: Only works if DEBUG enabled.
  DEBUG_MAX_APPS  = 500
  
  ### General Constants
  HREF      = "href"
  BR        = "<br />"
  NEW_LINE  = "\n"
  
  ### Reviews scraper
  # Xpath query to get the user reviews
  REVIEW_QUERY          = "/a:Document/a:View/a:ScrollView/a:VBoxView/a:View/a:MatrixView/a:VBoxView[position()=1]/a:VBoxView/a:VBoxView"
  # XML Namespace that apple uses for the reviews page. Need to pass this
  # namespace in order to do an XML search.
  REVIEW_NAMESPACE      = {'a' => 'http://www.apple.com/itms/'}
  # Curl command to retrieve the list of reviews for the apps
  # We specify the user agent and the apple country ID that itunes needs
  # in order to get the appropriate list.
  # There is no way to get all the reviews all at once so we need to ask for 
  # reviews in individual countries and then merge them.                      
  REVIEW_CURL_CMD       = "curl -s -A \"iTunes/9.2 (Macintosh; U; Mac OS X 10.6\" " +
                          "-H \"X-Apple-Store-Front: %s-1\" " + 
                          "'http://ax.phobos.apple.com.edgesuite.net/" + 
                          "WebObjects/MZStore.woa/wa/viewContentsUserReviews" + 
                          "?id=%s&pageNumber=%d&sortOrdering=4&type=Purple+Software' " + 
                          "| xmllint --format --recover - 2>/dev/null"
  # Regex to determine the rating a use gave an app
  REVIEW_RATING_REGEX   = /alt="(\d+) star(s?)"/
  # Regex to determine the version number of the app that was rated
  REVIEW_VERSION_REGEX  = /Version (.*)/

  ### App info scraper
  # The URL for the list of apps in the education category
  # NOTE: This needs to be converted to an array in order to suppoert multiple
  # categories
  APP_STORE_URL       = "http://itunes.apple.com/genre/ios-education/id6017?mt=8&letter=%s&page=%d"
  # Xpath query to determine if there is another page in the itunes list of apps
  NEXT_AVAILABLE      = "//ul[@class='list paginate']/li/a[@class='paginate-more']"
  # Xpath query to move cursor
  SCRAPE_START        = "div.grid3-column#selectedcontent"
  # Xpath query to get the app ID
  SCRAPE_QUERY        = "//div[@id='selectedcontent']/div/ul/li/a[contains(@href, 'id')]"
  # Regex to get the ID of an app
  APP_ID_REGEX        = /\/id(.*)\?/
  # URL for the iTunes lookup API. Parameters are app ID and country code
  # country code can be 'us' or 'ca' or any other 2 letter country code
  ITUNES_LOOKUP_URL   = "http://itunes.apple.com/lookup?id=%s&country=%s"
  # Apple's field that indicates how many results were fetched in the lookup API
  RESULT_COUNT        = "resultCount"
  
  ### RSS Feed links
  # Limit of RSS entries to request.
  # 2 <= RSS_LIMIT < 300
  # NOTE: RSS limit for new apps is always 100. They are not affected by this
  # number because apple always returns the same amount of apps
  RSS_LIMIT = 300
  # List of RSS feed links 
  RSS_LINKS = [
    { :name => 'top_free_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/topfreeapplications/limit=%d/genre=6017/json' },
    { :name => 'top_paid_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/toppaidapplications/limit=%d/genre=6017/json' },
    { :name => 'top_gros_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/topgrossingapplications/limit=%d/genre=6017/json' },
    { :name => 'top_free_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/topfreeipadapplications/limit=%d/genre=6017/json' },
    { :name => 'top_paid_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/toppaidipadapplications/limit=%d/genre=6017/json' },
    { :name => 'top_gros_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/topgrossingipadapplications/limit=%d/genre=6017/json' },
    { :name => 'new_apps',              :url => 'http://itunes.apple.com/%s/rss/newapplications/limit=%d/genre=6017/json' },
    { :name => 'new_free_apps',         :url => 'http://itunes.apple.com/%s/rss/newfreeapplications/limit=%d/genre=6017/json' },
    { :name => 'new_paid_apps',         :url => 'http://itunes.apple.com/%s/rss/newpaidapplications/limit=%d/genre=6017/json' }
  ]
  # XML Namespace that apple uses for the RSS feeds. Need to pass this
  # namespace in order to do an XML search.
  RSS_NAMESPACES  = {'a' => 'http://www.w3.org/2005/Atom', 'im' => 'http://itunes.apple.com/rss'}
  # Xpath query to search for app ids on the RSS feeds
  RSS_XPATH       = '//a:id[@im:id]'
  
  # List of stores with their corresponding name, itunes store id and country code.
  # To enable remove comment from the line and add the corresponding country code 
  STORES = [
  { :name => 'United States',        :id => 143441,   :code => 'us'},
  { :name => 'Canada',               :id => 143455,   :code => 'ca'}
#  { :name => 'Argentina',            :id => 143505},
#  { :name => 'Australia',            :id => 143460},
#  { :name => 'Belgium',              :id => 143446},
#  { :name => 'Brazil',               :id => 143503},
#  { :name => 'Chile',                :id => 143483},
#  { :name => 'China',                :id => 143465},
#  { :name => 'Colombia',             :id => 143501},
#  { :name => 'Costa Rica',           :id => 143495},
#  { :name => 'Croatia',              :id => 143494},
#  { :name => 'Czech Republic',       :id => 143489},
#  { :name => 'Denmark',              :id => 143458},
#  { :name => 'Deutschland',          :id => 143443},
#  { :name => 'Dominican Republic',   :id => 143508},
#  { :name => 'Ecuador',              :id => 143509},
#  { :name => 'Egypt',                :id => 143516},
#  { :name => 'El Salvador',          :id => 143506},
#  { :name => 'Espana',               :id => 143454},
#  { :name => 'Estonia',              :id => 143518},
#  { :name => 'Finland',              :id => 143447},
#  { :name => 'France',               :id => 143442},
#  { :name => 'Greece',               :id => 143448},
#  { :name => 'Guatemala',            :id => 143504},
#  { :name => 'Honduras',             :id => 143510},
#  { :name => 'Hong Kong',            :id => 143463},
#  { :name => 'Hungary',              :id => 143482},
#  { :name => 'India',                :id => 143467},
#  { :name => 'Indonesia',            :id => 143476},
#  { :name => 'Ireland',              :id => 143449},
#  { :name => 'Israel',               :id => 143491},
#  { :name => 'Italia',               :id => 143450},
#  { :name => 'Jamaica',              :id => 143511},
#  { :name => 'Japan',                :id => 143462},
#  { :name => 'Kazakhstan',           :id => 143517},
#  { :name => 'Korea',                :id => 143466},
#  { :name => 'Kuwait',               :id => 143493},
#  { :name => 'Latvia',               :id => 143519},
#  { :name => 'Lebanon',              :id => 143497},
#  { :name => 'Lithuania',            :id => 143520},
#  { :name => 'Luxembourg',           :id => 143451},
#  { :name => 'Macau',                :id => 143515},
#  { :name => 'Malaysia',             :id => 143473},
#  { :name => 'Malta',                :id => 143521},
#  { :name => 'Mexico',               :id => 143468},
#  { :name => 'Moldova',              :id => 143523},
#  { :name => 'Nederland',            :id => 143452},
#  { :name => 'New Zealand',          :id => 143461},
#  { :name => 'Nicaragua',            :id => 143512},
#  { :name => 'Norway',               :id => 143457},
#  { :name => 'Osterreich',           :id => 143445},
#  { :name => 'Pakistan',             :id => 143477},
#  { :name => 'Panama',               :id => 143485},
#  { :name => 'Paraguay',             :id => 143513},
#  { :name => 'Peru',                 :id => 143507},
#  { :name => 'Phillipines',          :id => 143474},
#  { :name => 'Poland',               :id => 143478},
#  { :name => 'Portugal',             :id => 143453},
#  { :name => 'Qatar',                :id => 143498},
#  { :name => 'Romania',              :id => 143487},
#  { :name => 'Russia',               :id => 143469},
#  { :name => 'Saudi Arabia',         :id => 143479},
#  { :name => 'Schweiz/Suisse',       :id => 143459},
#  { :name => 'Singapore',            :id => 143464},
#  { :name => 'Slovakia',             :id => 143496},
#  { :name => 'Slovenia',             :id => 143499},
#  { :name => 'South Africa',         :id => 143472},
#  { :name => 'Sri Lanka',            :id => 143486},
#  { :name => 'Sweden',               :id => 143456},
#  { :name => 'Taiwan',               :id => 143470},
#  { :name => 'Thailand',             :id => 143475},
#  { :name => 'Turkey',               :id => 143480},
#  { :name => 'United Arab Emirates', :id => 143481},
#  { :name => 'United Kingdom',       :id => 143444},
#  { :name => 'Uruguay',              :id => 143514},
#  { :name => 'Venezuela',            :id => 143502},
#  { :name => 'Vietnam',              :id => 143471},
]

  def self.getGammaInteretsts()
    return GAMMA_INTERESTS
  end
  
  def self.getGammaRatings()
    return GAMMA_RATINGS
  end
end
