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

  # もやもや結晶シート（入力・保存のみ）
  resources :survey_profiles, only: %i[new create]

  # 成長の星⭐（表示・編集・進捗管理）
  resources :goals, only: %i[index show edit update destroy] do
    # survey_profile の編集・更新をネストする
    resource :survey_profile, only: %i[edit update]  # ← ここを確認!

    member do
      get :progress  # 進捗状況ページ（オプション）
    end
  end
end
