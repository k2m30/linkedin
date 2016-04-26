require 'csv'

class Person < ActiveRecord::Base
  scope :mined, -> {where.not(notes: nil)}
  scope :has_emails, -> { where.not(email: [nil, '']) }
  scope :last_week, -> {where('created_at >= :date', date: DateTime.now.weeks_ago(1))}
  scope :to_be_mined, -> {where(notes: nil, email: nil).where.not(linkedin_id: nil)}

  class NoLinkedinIdException < StandardError;
  end

  def self.add_person(search_hash)
    Person.create!(name: search_hash[:name], position: search_hash[:position], industry: search_hash[:industry],
                   location: search_hash[:location], linkedin_id: search_hash[:linkedin_id], owner: search_hash[:owner], created_at: Time.now)
  end

  def self.add_email_to_person(linkedin_id, email)
    return nil if linkedin_id.nil? or email.nil?
    person = Person.find_by(linkedin_id: linkedin_id)
    person.update(email: email) unless person.nil?
    person
  end

  def self.exists?(params)
    raise NoLinkedinIdException.new(params) if params[:linkedin_id].nil?

    person = Person.find_by(linkedin_id: params[:linkedin_id])
    if person.present?
      return true
    else
      person = {}
      person[:name] = params[:name] if params[:name].present?
      person[:position] = params[:position] if params[:position].present?
      person[:industry] = params[:industry] if params[:industry].present?
      person[:location] = params[:location] if params[:location].present?
      person[:owner] = params[:owner] if params[:owner].present?
      person[:linkedin_id] = params[:linkedin_id] if params[:linkedin_id].present?

      add_person person
      return false
    end
  end

  def self.cleanup
    where(linkedin_id: nil).delete_all
    where.not(email: nil).each do |p|
      people = where(email: p.email)
      next if people.size <= 1

      people[1..-1].each do |d|
        d.delete
      end
    end
  end

  def self.export_to_csv(params)
    size, people = self.search(params)
    people = people.where(passed_to: nil)
    if people.nil? || people.empty?
      people = Person.where.not(linkedin_id: nil)
    end
    CSV.generate do |csv|
      csv << column_names
      people.each do |person|
        csv << person.attributes.values_at(*column_names)
      end
    end
  end

  def self.import_linkedin_db(file, owner_param, passed_to_param)
    begin
      # First Name
      # Last Name
      # E-mail Address
      # Company
      # Job Title
      CSV.foreach(file.path, headers: true, encoding: 'ISO-8859-1', row_sep: :auto, col_sep: ',') do |row|
        first_name = row['First Name'] || ''
        last_name = row['Last Name'] || ''
        name = first_name + ' ' + last_name

        position = row['Job Title'] || ''
        company = row['Company'] || ''
        email = row['E-mail Address']

        person = Person.find_by(email: email)
        if person.present?
          person.import_update(owner_param, passed_to_param)
          next
        end

        people = Person.where(name: name)
        if people.empty?
          Person.create(name: name, position: position << ' at ' << company, email: email)
        else
          if people.size == 1
            person = people.first
            person.update(email: email)
          else
            people.each do |person|
              if person.position.include?(position) && person.position.include?(company)
                person.update(name: name, email: email)
                break
              end
            end
          end
        end
      end
    rescue CSV::MalformedCSVError
      p ['end']
    end
  end

  def self.import_own_database_export(file, owner_param, passed_to_param)
    begin
      CSV.foreach(file.path, headers: true, encoding: 'ISO-8859-1', row_sep: :auto, col_sep: ',') do |row|
        linkedin_id = row['linkedin_id']
        person = Person.find_by(linkedin_id: linkedin_id)
        if person.present?
          person.import_update(owner_param, passed_to_param)
          next
        end
      end
    rescue CSV::MalformedCSVError
      p ['end']
    end

  end

  def import_update(owner_param, passed_to_param)
    update_hash = {}
    update_hash.merge!({owner: owner_param}) if owner_param.present? && owner.nil? && User.owner_exists?(owner_param)
    update_hash.merge!({passed_to: passed_to_param}) if passed_to_param.present? && passed_to.nil?
    update(update_hash) unless update_hash.empty?
  end

  def self.search(params)
    industry_id = params[:industry]
    passed_to = params[:passed_to]
    owner = params[:owner]
    search_hash = {}
    search_hash.merge!(industry: Industry.find(industry_id).name) unless industry_id.blank?
    search_hash.merge!(passed_to: passed_to) unless passed_to.blank?
    search_hash.merge!(owner: owner) unless owner.blank?

    people = Person.where(search_hash)
    query = params[:query]
    if query.present?
      people = people.where('name ilike :q or position ilike :q', q: "%#{query}%")
    end
    return people.size, people
  end
end