module AppileoParserHelper
  
  # Determine if a sentence is similar to a tag
  def self.words_match_tag(words, tag)
    result = false
    words.split(/\W+/).each do |word|
      result = true if word_match_tag(words, tag)
    end
    result
  end
  
  # Determine if a word is similar to a list of tags
  # A word is similar to a tag only if its similar to any 
  #  of the matches in that tag
  def self.word_match_tag(word, tag)
    result = false
    word = word.downcase
    tag.matches.each do |match|
      result = true if isSimilar(word, match)
    end
    result
  end
  
  # Returns true if the word is similar to the tag
  def self.isSimilar(word, tag)
    tag = tag.lowercase
    word = word.lowercase
    if tag == word
      return true
    elsif tag.pluralize == word
      return true
    elsif word =~ /\A#{tag}/ != nil
      return true
    end
    false
  end
  
  # Merge two cateogry arrays
  def self.merge_categories(cats1, cats2)
    merged = []
    cats1.each_pair do |cat_name, cat1_value|
      if cats2.has_key? cat_name
        merged[cat_name] = merge_array(cat1_value, cats2[cat_name])
      else
        merged[cat_name] = cat1_value
      end
    end
    merged
  end
  
  # Return the merged results of two arrays, removing duplicates
  def self.merge_array(a1, a2)
    if a1.count == 0
      return a2
    elsif a2.count == 0
      return a1
    end
    merged = a1.clone
    a2.each do |value|
      merged << value if not a1.include?(value)
    end
    merged
  end
  
end