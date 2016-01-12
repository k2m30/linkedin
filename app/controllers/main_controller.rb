class MainController < ApplicationController
  def index

  end

  def download_base
      send_file('db/development.sqlite3')
  end
end