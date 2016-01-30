require 'csv'

class Person < ActiveRecord::Base
  # def self.import(file = '../2ndconnections.csv')
  #   records = CSV.read(file)
  #
  #   records.uniq.each do |record|
  #     Person.create(name: record[0], position: record[1], industry: record[2], location: record[3])
  #   end
  # end

  def self.add_user(params)
    Person.create(name: params[:name], position: params[:position], industry: params[:industry],
                  location: params[:location], linkedin_id: params[:linkedin_id], owner: params[:owner], creared_at: Time.now)
  end

  def self.add_email_to_person(linkedin_id, email)
    return nil if linkedin_id.nil? or email.nil?
    person = Person.find_by(linkedin_id: linkedin_id)
    person.update(email: email) unless person.nil?
    person
  end

  def self.pipl_research(n=100)
    require 'pipl'

    people = Person.where.not(linkedin_id: nil).where(notes: nil, email: nil).limit(n)
    people.each do |p|
      p p
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
    end
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

  def self.import(file)
    begin
      CSV.foreach(file.path, headers: true, encoding: 'ISO-8859-1', row_sep: :auto, col_sep: ',') do |row|
        name = row['First Name'] << ' ' << row['Last Name']
        position = row['Job Title'] << ' at ' << row['Company']
        email = row['E-mail Address']

        people = Person.where(name: name)
        if people.empty?
          Person.create(name: name, position: position, email: email)
          p ['create', name]
        else
          if people.size == 1
            people.first.update(email: email) if people.first.email.nil?
          else
            people.each do |person|
              if person.position.include?(row['Job Title']) && person.position.include?(row['Company'])
                person.update(email: email) if person.email.nil?
                p ['update', person]
              end
            end
          end
          # Frank		Garcia		twotonlogistics@gmail.com	Two Ton Logistics Ltd		Owner/Managing Director
          # Frank Garcia	Owner/Director at Two Ton Logistics Ltd	Transportation/Trucking/Railroad	London, United Kingdom	27726532
        end
      end
    rescue CSV::MalformedCSVError
      p ['end']
    end

  end
end
