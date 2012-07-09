namespace :scraper do
  
  task :scrap_all do
    system 'rails runner lib/tasks/scraper/scraper.rb -- -c -r -a'
  end
  
  task :scrap_rankings do
    system 'rails runner lib/tasks/scraper/scraper.rb -- -c -r -R'
  end
  
end