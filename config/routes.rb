Rails.application.routes.draw do
  root 'main#index'

  get 'person' => 'persons#person_exists'
  get 'next_url' => 'persons#get_next_url'
  get 'count' => 'persons#count'
  get 'export' => 'persons#export'
  get 'add_email' => 'persons#add_email_to_person'
  post 'import' => 'persons#import'
  get 'download' => 'main#download_base'
end
