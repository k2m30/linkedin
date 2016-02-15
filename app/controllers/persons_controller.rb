class PersonsController < ApplicationController
  def export

    respond_to do |format|
      format.html do
        @people = Person.where.not(notes: nil).limit(10)
      end
      format.csv { send_data Person.export_to_csv }
    end
  end

  def import
    Person.import params[:file], params[:owner], params[:passed_to]
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
    @people = Person.search(params)
    @status =  'Total: ' << Person.count.to_s <<
        ', Emails: ' << Person.where.not(email: nil).count.to_s <<
        ', Linkedin IDs: ' << Person.where.not(linkedin_id: nil).count.to_s <<
        ', Notes: ' << Person.where.not(notes: nil).count.to_s <<
        ', Have owner: ' << Person.where.not(owner: nil).count.to_s <<
        ', Passed to: ' << Person.where.not(passed_to: nil).count.to_s
  end
end
