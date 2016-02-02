class Keyword < ActiveRecord::Base
  def self.get_next_url(owner, industry)
    return nil if owner.nil? || industry.nil? || owner.blank? || industry.blank?
    keyword = find_by(owner: owner, industry: industry.to_i, passed: false)
    if keyword.nil?
      multiply_keywords(owner, industry)
      keyword = find_by(owner: owner, passed: false)
      return nil if keyword.nil?
    end
    keyword.update(passed: true)
    "https://www.linkedin.com/vsearch/p?keywords=#{keyword.keyword.gsub(' ', '%20')}&title=#{keyword.position.gsub(' ', '%20')}&openAdvancedForm=true&titleScope=C&locationType=I&countryCode=gb&rsid=4120029691454119532620&orig=FCTD&openFacets=N,G,CC,I&f_N=S&f_I=#{industry}"
  end

  def self.multiply_keywords(owner, industry, file_name = '/config/users/keywords.yml')
    file = Rails.root.to_s + file_name
    data = File.open(file) { |yf| YAML::load(yf) }
    positions = data['positions'].split(', ')

    industry_str = data['industries'].key(industry.to_i)
    keywords = data['keywords'][industry_str].split(',') + data['keywords']['All'].split(',')
    keywords.insert 0, ''

    keywords.each do |keyword|
      positions.each do |position|
        Keyword.find_or_create_by(owner: owner, position: position, keyword: keyword, industry: industry.to_i)
      end
    end
  end
end