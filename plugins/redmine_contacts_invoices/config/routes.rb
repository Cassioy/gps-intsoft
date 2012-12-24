resources :invoices do
   	collection do 
   		get :bulk_edit, :context_menu
   		post :bulk_edit, :bulk_update
   		delete :bulk_destroy 
   	end
end

resources :projects do
	resources :invoices, :only => [:index, :new, :create]              
end

match "invoices_time_entries/:action", :controller => "invoices_time_entries"
  
