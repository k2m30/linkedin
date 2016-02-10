class Industry < ActiveRecord::Base
  validates :name, uniqueness: true
  has_many :users

  def self.positions
    'Business owner, CEO, Chairman, CIO, Co-founder, CTO, CXO, Founder, Head of, Managing director, Owner, President, VP, Vice President'
  end

  def self.load_industries(file_name = '/config/users/keywords.yml')
    file = Rails.root.to_s + file_name
    data = File.open(file) { |yf| YAML::load(yf) }

    data['industries'].each_pair do |industry, index|
      Industry.create(name: industry, index: index, keywords: data['keywords'][industry])
    end
  end
end
