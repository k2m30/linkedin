require 'csv'

class Person < ActiveRecord::Base
  def self.import(file = '../2ndconnections.csv')
    records = CSV.read(file)

    records.uniq.each do |record|
      Person.create(name: record[0], position: record[1], industry: record[2], location: record[3])
    end
  end

  def self.add_user(params)
    Person.create(name: params[:name], position: params[:position], industry: params[:industry],
                  location: params[:location], linkedin_id: params[:linkedin_id])
  end

  def self.exists?(params)
    search_hash = {}
    search_hash[:name] = params[:name] if params[:name].present?
    search_hash[:position] = params[:position] if params[:position].present?
    search_hash[:industry] = params[:industry] if params[:industry].present?
    search_hash[:location] = params[:location] if params[:location].present?


    return false if search_hash.empty?
    user = Person.find_by search_hash
    if user.present? && user.linkedin_id.nil? && params[:linkedin_id].present?
      user.update linkedin_id: params[:linkedin_id]
    end

    if search_hash.size == 4 && user.nil? && params[:linkedin_id].present?
      search_hash[:linkedin_id] = params[:linkedin_id]
      add_user search_hash
    end

    user.present?
  end

  def self.export_to_csv
    CSV.generate do |csv|
      csv << column_names
      Person.where.not(linkedin_id: nil).each do |person|
        csv << person.attributes.values_at(*column_names)
      end
    end
  end
end
