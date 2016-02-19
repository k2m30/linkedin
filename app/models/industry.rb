class Industry < ActiveRecord::Base
  validates :name, uniqueness: true
  has_many :users

  def self.positions
    'Business owner, LION, Director, CEO, Chairman, CIO, Co-founder, COO, CTO, CXO, Founder, Head of, Manager, Managing director, Owner, President, VP, Vice President'
  end

  def self.load_industries(file_name = '/config/users/keywords.yml')
    file = Rails.root.to_s + file_name
    data = File.open(file) { |yf| YAML::load(yf) }

    data['industries'].each_pair do |industry, index|
      ind = Industry.find_by(name: industry, index: index)
      if ind.nil?
        Industry.create(name: industry, index: index, keywords: data['keywords'][industry]||'service')
      else
        ind.update(keywords: data['keywords'][industry]||'service')
      end
    end
  end
end
