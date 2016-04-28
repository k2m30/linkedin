require 'pipl'

class Miner < ActiveJob::Base
  queue_as :default

  def perform(params)
    industry = Industry.find(params[:industry]).name || 'Transportation/Trucking/Railroad'
    n = params[:number].to_i || 100
    Delayed::Worker.logger.warn("Mining started,  #{industry}, #{n})"

    processed = 0
    skipped = 0
    not_found = 0
    emails_before = Person.has_emails.size

    people = Person.to_be_mined.where(industry: industry).limit(n)
    people.each do |p|
      if p.name.split(' ').size != 2
        p.update(notes: '{}', email: '')
        skipped+=1
        next
      end
      first, last = p.name.split(' ')

      if last.include?('.') or first.include?('.') or last.size == 1 or first.size == 1
        p.update(notes: '{}', email: '')
        skipped+=1
        next
      end

      person = Pipl::Person.new
      person.add_field Pipl::Name.new(first: first, last: last)
      person.add_field Pipl::UserID.new content: "#{p.linkedin_id}@linkedin".freeze
      response = Pipl::client.search person: person, api_key: 'pije3hnj534fimtabpzx5fgn'.freeze

      processed+=1
      if response.person.nil?
        p.update(notes: '{}', email: '')
        not_found+=1
        next
      end
      emails = response.person.emails.map(&:address)
      # emails.delete_if { |e| e.include? 'facebook' }

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
    end

    emails_after = Person.has_emails.size
    Delayed::Worker.logger.warn("Mining finished, #{processed} API requests made, #{emails_after-emails_before}" <<
                                    " emails found, #{not_found} not found, #{skipped} skipped")
  end
end