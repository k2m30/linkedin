require 'csv'

class Person < ActiveRecord::Base
  class NoLinkedinIdException < StandardError; end

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

  def self.pipl_research(n=100)
    require 'pipl'

    people = Person.where.not(linkedin_id: nil).where(notes: nil, email: nil, industry: 'Transportation/Trucking/Railroad').limit(n)
    people.each do |p|
      next if p.name.split(' ').size != 2
      first, last = p.name.split(' ')

      next if last.include?('.') or first.include?('.')
      next if last.size == 1 or first.size == 1

      person = Pipl::Person.new
      person.add_field Pipl::Name.new(first: first, last: last)
      person.add_field Pipl::UserID.new content: "#{p.linkedin_id}@linkedin"
      response = Pipl::client.search person: person, api_key: 'pije3hnj534fimtabpzx5fgn'

      if response.person.nil?
        p.update(email: '')
        next
      end
      emails = response.person.emails.map(&:address)
      emails.delete_if{|e| e.include? 'facebook'}

      # byebug
      notes = response.person.to_hash.to_s
      if emails.size > 1
        email = emails.shift
        notes << "\n" << emails.join(' ')
      else
        email = emails.first
      end
      p.update(email: email, notes: notes)
      p [p.name, p.email]
      p notes
    end
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

  def self.export_to_csv(params)
    size, people = self.search(params)
    if people.nil?
      people = Person.where.not(linkedin_id: nil)
    end
    CSV.generate do |csv|
      csv << column_names
      people.each do |person|
        csv << person.attributes.values_at(*column_names)
      end
    end
  end

  def self.import(file, owner_param, passed_to_param)
    begin
      CSV.foreach(file.path, headers: true, encoding: 'ISO-8859-1', row_sep: :auto, col_sep: ',') do |row|
        first_name = row['First Name'] || ''
        last_name = row['Last Name'] || ''
        name = first_name + ' ' + last_name
        name = row['Full Name'] if row['First Name'].nil? and row['Last Name'].nil?
        job_title = row['Job Title'] || ''
        company = row['Company'] || ''
        position = job_title + ' at ' + company

        email = row['E-mail Address']
        people = Person.where(name: name)
        if people.empty?
          Person.create(name: name, position: position, email: email, owner: owner_param, passed_to: passed_to_param)
          p ['create', name]
        else
          if people.size == 1
            person = people.first
            person.import_update(email, owner_param, passed_to_param)
          else
            people.each do |person|
              if person.position.include?(job_title) && person.position.include?(company)
                person.import_update(email, owner_param, passed_to_param)
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

  def import_update(email_param, owner_param, passed_to_param)
    update_hash = {}
    update_hash.merge!({email: email_param}) if email_param.present? && email.nil?
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
