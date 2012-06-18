module ApplicationHelper
  
  def to_camel(words)
    uncapitalize(words.split(/\s+/).map(&:capitalize).join)
  end
  
  def uncapitalize(word)
    word[0,1].downcase + word[1..-1]
  end
  
  def get_from_file(file)
    content = nil
    File.open(file, 'r+') do |f|
      content = ActiveSupport::JSON.decode f.read 
    end
    content
  end

  def save_to_file(file, content)
    File.open(file, 'w+') do |f|
      f.write ActiveSupport::JSON.encode content
    end
  end
  
end
