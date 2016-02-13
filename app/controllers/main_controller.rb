class MainController < ApplicationController
  def index
    @owners = User.all
  end

  def download_base
    file_name = "db/db#{DateTime.now.to_formatted_s(:number)}.dump"
    `pg_dump linkedin > #{file_name}`
    send_file(file_name)
  end
end