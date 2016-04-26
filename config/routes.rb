Rails.application.routes.draw do


  resources :pipls, only: [:index] do
    collection do
      get 'research'
    end
  end

  resources :industries
  resources :users do
    member do
      get 'keywords'
      get 'reset_keywords'
      get 'multiply_keywords'
      get 'log'
      get 'pause'
      get 'unpause'
    end
    resources :keywords, only: [] do
      member do
        get 'revert'
      end
    end
  end
  root 'main#index'

  get 'stats' => 'persons#stats'
  get 'person' => 'persons#person_exists'
  get 'next_url' => 'persons#get_next_url'
  get 'count' => 'persons#count'
  get 'export' => 'persons#export'
  get 'add_email' => 'persons#add_email_to_person'
  post 'import' => 'persons#import'
  get 'download' => 'main#download_base'
  get 'search' => 'persons#search'
  mount Tail::Engine, at: '/tail'
end
