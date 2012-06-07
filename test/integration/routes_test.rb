require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  test "route test" do
    # In order to test from console get 'routes = Rails.application.routes'
    # run routes.recongnize_path('url path')
    
    assert_routing( { :path => "lookup", :method => :get },
                    { :controller => "app_data", :action => "lookup_data" })
    
    assert_routing( { :path => "/top", :method => :get },
                    { :controller => "app_data", :action => "top_data"})
    
    assert_routing( { :path => "/top/iphone", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "iphone"})
    assert_routing( { :path => "/top/iphone/free", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "iphone", :category=>"free" })
    assert_routing( { :path =>"/top/iphone/paid", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "iphone", :category=>"paid" })
    assert_routing( { :path =>"/top/iphone/grossing", :method => :get }, 
                    { :controller => "app_data", :action => "top_data", :device => "iphone", :category=>"grossing" })
    
    assert_routing( { :path => "/top/ipad", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "ipad"})
    assert_routing( { :path => "/top/ipad/free", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "ipad", :category=>"free" })
    assert_routing( { :path =>"/top/ipad/paid", :method => :get },
                    { :controller => "app_data", :action => "top_data", :device => "ipad", :category=>"paid" })
    assert_routing( { :path =>"/top/ipad/grossing", :method => :get }, 
                    { :controller => "app_data", :action => "top_data", :device => "ipad", :category=>"grossing" })
    
    assert_routing( { :path => "/new", :method => :get },
                    { :controller => "app_data", :action => "new_data"})
    
    assert_routing( { :path => "/new/iphone", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "iphone"})
    assert_routing( { :path => "/new/iphone/free", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "iphone", :category=>"free" })
    assert_routing( { :path =>"/new/iphone/paid", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "iphone", :category=>"paid" })
    assert_routing( { :path =>"/new/iphone/grossing", :method => :get }, 
                    { :controller => "app_data", :action => "new_data", :device => "iphone", :category=>"grossing" })
    
    assert_routing( { :path => "/new/ipad", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "ipad"})
    assert_routing( { :path => "/new/ipad/free", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "ipad", :category=>"free" })
    assert_routing( { :path =>"/new/ipad/paid", :method => :get },
                    { :controller => "app_data", :action => "new_data", :device => "ipad", :category=>"paid" })
    assert_routing( { :path =>"/new/ipad/grossing", :method => :get }, 
                    { :controller => "app_data", :action => "new_data", :device => "ipad", :category=>"grossing" })
    
  end
end
