class HomeController < ApplicationController
  def index
    interests = params[:interests]
    logger.info "interests: #{interests}"
    
    results = [
      { 
        name: "Draco Rocks",
        apps: AppData.all[0..0]
      },
      {
        name: "Section two",
        apps: AppData.all[1..1]
      },
      {
        name: "Section three",
        apps: AppData.all[2..2]
      }
    ]
    
    render :json => {
      success: true,
      message: "Success",
      home_data: results.as_json
    }
  end
end
