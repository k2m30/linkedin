Rails.application.routes.draw do
  root 'main#index'

  get 'person' => 'persons#person_exists'
  get 'count' => 'persons#count'
  get 'export' => 'persons#export'
  get 'add_email' => 'persons#add_email_to_person'
  post 'import' => 'persons#import'
end