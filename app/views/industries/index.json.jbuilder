json.array!(@industries) do |industry|
  json.extract! industry, :id, :index, :keywords, :name
  json.url industry_url(industry, format: :json)
end
