class User < ActiveRecord::Base
  validates :dir, uniqueness: true
  belongs_to :industry

  def self.load_users(file='config/users/users.yml')
    file = Rails.root + file
    users = File.open(file) { |yf| YAML::load(yf) }
    users.keys.map { |key| User.create(login: users[key]['l'], password: users[key]['p'],
                                    proxy: users[key]['proxy'], dir: users[key]['dir'], industry: Industry.find_by(index: users[key]['industry'].to_i),
                                    command_str: "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --enable-udd-profiles --user-data-dir=#{ENV['HOME']}/1chrm/#{users[key]['dir']}") }
  end

  def get_next_url(update_to_passed=true, third_connections=false)

    keyword = next_keyword
    if keyword.nil?
      multiply_keywords
      keyword = next_keyword
      return nil if keyword.nil?
    end
    keyword.update(passed: true) if update_to_passed

    connections_letter = third_connections ? 'O' : 'S'
    url = "https://www.linkedin.com/vsearch/p?keywords=#{keyword.keyword.gsub(' ', '%20')}&title=#{keyword.position.gsub(' ', '%20')}&openAdvancedForm=true&titleScope=C&locationType=I&countryCode=gb&rsid=4120029691454119532620&orig=FCTD&openFacets=N,G,CC,I&f_N=#{connections_letter}"
    url+= "&f_I=#{self.industry.index}" unless self.industry.name == 'All'
    url
  end

  def get_next_key
    keyword = next_keyword
    if keyword.nil?
      multiply_keywords
      keyword = next_keyword
    end
    keyword
  end

  def next_keyword
    Keyword.where(owner: self.dir, passed: false, industry: self.industry.index.to_i, keyword: '').sample || Keyword.where(owner: self.dir, passed: false, industry: self.industry.index.to_i).sample
  end

  def self.owner_exists?(owner)
    find_by(dir: owner).nil? ? false : true
  end

  def multiply_keywords
    Keyword.where(owner: self.dir).destroy_all

    positions = Industry.positions.split(', ')

    keywords = self.industry.keywords.split(',') + Industry.find_by(index: 0).keywords.split(',')
    keywords.insert 0, ''

    keywords.each do |keyword|
      positions.each do |position|
        Keyword.find_or_create_by(owner: self.dir, position: position, keyword: keyword, industry: self.industry.index.to_i)
      end
    end
  end
end