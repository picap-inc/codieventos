Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Admin namespace
  namespace :admin do
    root 'admin_application#index'
    
    # Authentication routes
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    
    # QR Code attendance marking
    get 'attendance/:event_id/:assistant_id', to: 'assistants#mark_attendance', as: 'mark_attendance'
    
    resources :events do
      resources :assistants
      member do
        post :upload_assistants
        delete :remove_all_assistants
        post :send_all_whatsapp_invitations
      end
    end
    resources :assistants, only: [:index, :show] do
      member do
        post :send_whatsapp_invitation
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
