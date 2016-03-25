require 'pipl'

class Miner < ActiveJob::Base
  queue_as :default

  def perform(params)
    Delayed::Worker.logger.warn('Mining started' + params.to_s)

    industry = Industry.find(params[:industry]).name || 'Transportation/Trucking/Railroad'
    n = params[:number].to_i || 100

    processed = 0
    emails_before = Person.has_emails.size

    people = Person.to_be_mined.where(industry: industry).limit(n)
    people.each do |p|
      if p.name.split(' ').size != 2
        p.update(notes: '{}', email: '')
        next
      end
      first, last = p.name.split(' ')

      if last.include?('.') or first.include?('.') or last.size == 1 or first.size == 1
        p.update(notes: '{}', email: '')
        next
      end

      person = Pipl::Person.new
      person.add_field Pipl::Name.new(first: first, last: last)
      person.add_field Pipl::UserID.new content: "#{linkedin_id}@linkedin"
      # person.add_field Pipl::UserID.new content: "#{p.linkedin_id}@linkedin"
      response = Pipl::client.search person: person, api_key: 'pije3hnj534fimtabpzx5fgn'

      if response.person.nil?
        p.update(notes: '{}', email: '')
        next
      end
      emails = response.person.emails.map(&:address)
      emails.delete_if { |e| e.include? 'facebook' }

      # byebug
      notes = response.person.to_hash.to_s
      if emails.size > 1
        email = emails.shift
        notes << "\n" << emails.join(' ')
      else
        email = emails.first
      end
      p.update(email: email, notes: notes)
      puts [p.name, p.email]
      processed+=1
    end

    emails_after = Person.has_emails.size
    Delayed::Worker.logger.warn("Mining finished, #{processed} API requests made, #{emails_after-emails_before} emails found")
  end
end