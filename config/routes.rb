Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root 'static_pages#top'
  get 'terms', to: 'static_pages#terms'
  get 'privacy', to: 'static_pages#privacy'
  get 'contact', to: 'static_pages#contact'

  resources :users, only: %i[new create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  # プロフィール
  resource :profile, only: [:show, :edit, :update]

  # もやもや結晶シート（入力・保存のみ）
  resources :survey_profiles, only: %i[new create] do
    collection do
      post :fetch_ai_suggestion 
    end
  end

  # 成長の星
  resources :goals, only: %i[index show edit update destroy] do
    # survey_profile の編集・更新をネストする
    resource :survey_profile, only: %i[edit update]

    # 輝き（Spark）
    resources :sparks, only: [:create, :edit, :update, :destroy] do
      member do
        get :cancel
      end
    end
  end
end
