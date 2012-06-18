Appileo::Application.routes.draw do
  
  #Constraint dictionary for path values of the API calls
  constraint_dict = { :device => /iphone|ipad/,
                      :category => /free|paid|gros/,
                      :country => /us|ca/
                    }
  
  # This route can be invoked with
  #lookup_url()
  match "/lookup"                     => "app_data#lookup_data",
        :via => [:get],
        :as => :lookup
  
  # This route can be invoked with
  # top_url(:device => iphone|ipad, :category => free|paid|grossing, :country => us|ca)      
  match "/top/:device/:category/:country"  => "app_data#top_data",
        :via => [:get],
        :constraints => constraint_dict,
        :as => :top
  
  # This route can be invoked with
  # new_url(:device => iphone|ipad, :category => free|paid|grossing)      
  match "/new/:category"  => "app_data#new_data",
        :via => [:get],
        :constraints => constraint_dict,
        :as => :new

  # Root of the site
  # note: public/index.html has to be removed
  root  :to => "home#index",
        :via => [:get],
        :as => :home


  # Category and interest editors
  match "/categories", to: 'categories#index'
  match "/update", to: 'categories#update', via: :post
  match "/destroy", to: 'categories#destroy', via: :delete
  match "/categories/raw", to: 'categories#raw'

  match "/interests", to: 'interests#index'
  match "/interests_update", to: 'interests#update', via: :post
  match "/interests_destroy", to: 'interests#destroy', via: :delete
  match "/interests/raw", to: 'interests#raw'
end
