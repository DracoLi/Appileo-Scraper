Appileo::Application.routes.draw do
  
  #Constraint dictionary for path values of the API calls
  constraint_dict = { :device => /iphone|ipad/,
                      :category_top => /free|paid|gros/,
                      :category_new => /free|paid/,
                      :country => /us|ca/
                    }
  
  # This route can be invoked with
  #lookup_url()
  match "/lookup"                     => "app_data#lookup_data",
        :via => [:get],
        :as => :lookup
  
  # This route can be invoked with
  # top_url(:device => iphone|ipad, :category => free|paid|grossing, :country => us|ca)      
  match "/top/:country/:device/:category_top"  => "app_data#top_data",
        :via => [:get],
        :constraints => constraint_dict,
        :as => :top
  
  # This route can be invoked with
  # new_url(:device => iphone|ipad, :category => free|paid)      
  match "/new/:country(/:category_new)"  => "app_data#new_data",
        :via => [:get],
        :constraints => constraint_dict,
        :as => :new

  # Root of the site
  # note: public/index.html has to be removed
  root  :to => "home#index",
        :via => [:get],
        :as => :home

end
