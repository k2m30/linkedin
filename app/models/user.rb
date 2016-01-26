class User
  attr_accessor :id, :login, :password, :proxy, :url, :dir

  def initialize(id='name', login='hilton.joel@yahoo.com', password='Razdvatri!23123', proxy='', dir='', url='')
    @id = id
    @login = login
    @password = password
    @proxy = proxy
    @url = url
    @dir = dir
  end

  def to_hash
    {@id => {'l' => @login, 'p' => @password, 'proxy'=> @proxy, 'dir' =>@dir, 'url' => @url}}
  end

  def get_next_url
    path = "../../config/users/#{@dir}.csv"
    table = CSV.read path, headers: true
    table.by_row!

    row = table.find{|r| r['Status (new / used)'] == 'new'}
    row['Status (new / used)'] = 'used'
    File.open(path, 'w') do |f|
      f.write table.to_csv
    end

    row['Results']
  end
end