module ScraperConstants

  # Debug info
  DEBUG           = true
  DEBUG_MAX_PAGES = 1
  DEBUG_MAX_APPS  = 2
  
  # General Constants
  HREF      = "href"
  BR        = "<br />"
  NEW_LINE  = "\n"
  
  # Reviews scraper
  REVIEW_QUERY          = "/a:Document/a:View/a:ScrollView/a:VBoxView/a:View/a:MatrixView/a:VBoxView[position()=1]/a:VBoxView/a:VBoxView"
  REVIEW_NAMESPACE      = {'a' => 'http://www.apple.com/itms/'}                      
  REVIEW_CURL_CMD       = "curl -s -A \"iTunes/9.2 (Macintosh; U; Mac OS X 10.6\" " +
                          "-H \"X-Apple-Store-Front: %s-1\" " + 
                          "'http://ax.phobos.apple.com.edgesuite.net/" + 
                          "WebObjects/MZStore.woa/wa/viewContentsUserReviews" + 
                          "?id=%s&pageNumber=%d&sortOrdering=4&type=Purple+Software' " + 
                          "| xmllint --format --recover - 2>/dev/null"

  REVIEW_RATING_REGEX   = /alt="(\d+) star(s?)"/
  REVIEW_VERSION_REGEX  = /Version (.*)/

  # App info scraper
  APP_STORE_URL       = "http://itunes.apple.com/genre/ios-education/id6017?mt=8&letter=%s&page=%d"
  NEXT_AVAILABLE      = "//ul[@class='list paginate']/li/a[@class='paginate-more']" 
  SCRAPE_START        = "div.grid3-column#selectedcontent"
  SCRAPE_QUERY        = "//div[@id='selectedcontent']/div/ul/li/a[contains(@href, 'id')]"
  APP_ID_REGEX        = /\/id(.*)\?/
  ITUNES_LOOKUP_URL   = "http://itunes.apple.com/lookup?id=%s&country=%s"
  RESULT_COUNT        = "resultCount"
  
  # RSS Feed links
  RSS_LIMIT = 2
  RSS_LINKS = [
    { :name => 'top_free_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/topfreeapplications/limit=%d/genre=6017/json' },
    { :name => 'top_paid_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/toppaidapplications/limit=%d/genre=6017/json' },
    { :name => 'top_gros_apps_iphone',  :url => 'http://itunes.apple.com/%s/rss/topgrossingapplications/limit=%d/genre=6017/json' },
    { :name => 'top_free_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/topfreeipadapplications/limit=%d/genre=6017/json' },
    { :name => 'top_paid_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/toppaidipadapplications/limit=%d/genre=6017/json' },
    { :name => 'top_gros_apps_ipad',    :url => 'http://itunes.apple.com/%s/rss/topgrossingipadapplications/limit=%d/genre=6017/json' },
    #{ :name => 'new_apps',              :url => 'http://itunes.apple.com/%s/rss/newapplications/limit=%d/genre=6017/json' },
    #{ :name => 'new_free_apps',         :url => 'http://itunes.apple.com/%s/rss/newfreeapplications/limit=%d/genre=6017/json' },
    #{ :name => 'new_paid_apps',         :url => 'http://itunes.apple.com/%s/rss/newpaidapplications/limit=%d/genre=6017/json' }
  ]
  RSS_NAMESPACES  = {'a' => 'http://www.w3.org/2005/Atom', 'im' => 'http://itunes.apple.com/rss'}
  RSS_XPATH       = '//a:id[@im:id]'
  
  # List of stores, to enable remove comment from the line and add 
  # the corresponding apple store code 
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
end
