Rails.application.routes.draw do
  root 'main#index'

  get 'person' => 'persons#person_exists'
  get 'count' => 'persons#count'
  # get 'add_person' => 'persons#add_person'
end
