
class KeywordAnalysis < ActiveRecord::Base
  belongs_to :keyword
  
  def self.update_keyword_rankings
    keywords = Keyword.all
    
    keywords.each do |keyword|
      keyword.fetch_keywordanalysis
    end
  end
end
