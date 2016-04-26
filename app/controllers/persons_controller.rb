class PersonsController < ApplicationController
  def export

    respond_to do |format|
      format.html do
        @people = Person.where.not(notes: nil).limit(10)
      end
      format.csv do
        send_data Person.export_to_csv(params)
      end
    end
  end

  def stats
    @stats = Industry.all.map do |industry|
      [industry.name, Person.where(industry: industry.name).where.not(email: [nil, '']).size]
    end.sort_by{|r| r[1]}.reverse
  end

  def import
    case params[:type_of_file]
      when 'linkedin_db'
        Person.import_linkedin_db params[:file], params[:owner], params[:passed_to]
      when 'database_export'
        Person.import_own_database_export params[:file], params[:owner], params[:passed_to]
    end
    redirect_to root_path, notice: 'Imported'
  end

  def add_email_to_person
    person = Person.add_email_to_person(params[:linkedin_id], params[:email])
    render text: person
  end

  def person_exists
    render text: Person.exists?(params)
  end

  def get_next_url
    @user = User.find(params[:id])
    render test: 'false' if @user.nil?
    render text: @user.get_next_url || 'false'
  end

  def count
    render text: 'Total: ' << Person.count.to_s <<
        ', Emails: ' << Person.where.not(email: nil).count.to_s <<
        ', Linkedin IDs: ' << Person.where.not(linkedin_id: nil).count.to_s <<
        ', Notes: ' << Person.where.not(notes: nil).count.to_s
  end

  def search
    @size, @people = Person.search(params)
    @people = @people.limit(100)
    @status =  'Total: ' << Person.count.to_s <<
        ', Emails: ' << Person.where.not(email: nil).count.to_s <<
        ', Linkedin IDs: ' << Person.where.not(linkedin_id: nil).count.to_s <<
        ', Notes: ' << Person.where.not(notes: nil).count.to_s <<
        ', Have owner: ' << Person.where.not(owner: nil).count.to_s <<
        ', Passed to: ' << Person.where.not(passed_to: nil).count.to_s
  end
end
