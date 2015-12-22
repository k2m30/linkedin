class PersonsController < ApplicationController
  def export
    respond_to do |format|
      format.csv {send_data Person.export_to_csv}
    end
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
