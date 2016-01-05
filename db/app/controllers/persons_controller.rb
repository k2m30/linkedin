class PersonsController < ApplicationController
  def export
    @people = Person.all
    respond_to do |format|
      format.html# {render text: Person.export_to_csv}
      format.csv {send_data Person.export_to_csv}
    end
  end

  def import
    Person.import params[:file]
    redirect_to root_path, notice: 'Imported'
  end

  def person_exists
    render text: Person.exists?(params)
  end

  def add_person
    Person.add_person(params)
    render text: 'ok'
  end

  def count
    render text: Person.count
  end
end
