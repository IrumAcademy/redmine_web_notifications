resources :web_notifications, only: [:index, :show] do
  collection do
    get :recent
    get :poll
    post :read_all
  end
  member do
    post :read
  end
end
