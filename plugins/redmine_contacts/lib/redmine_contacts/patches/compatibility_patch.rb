require_dependency 'application_controller'  

if (Redmine::VERSION.to_a.first(3).join('.') < '1.3.0') 
    def labelled_fields_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => TabularFormBuilder})
      fields_for(*args, &proc)
    end

    def labelled_remote_form_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => TabularFormBuilder})
      remote_form_for(*args, &proc)
    end
    
    def labelled_form_for(*args, &proc)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options.merge!({:builder => TabularFormBuilder})
      form_for(*args, &proc)
    end

    def build_query_from_params
      if params[:fields] || params[:f]
        @query.filters = {}
        @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
      else
        @query.available_filters.keys.each do |field|
          @query.add_short_filter(field, params[field]) if params[field]
        end
      end
      @query.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
      @query.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    end
end  

module RedmineContacts
  module Patches  

    module SettingCompatibilityPatch
      module ClassMethods    

        def issue_group_assignment?
          false
        end
      end  

      def self.included(base) # :nodoc: 
        base.extend(ClassMethods)
      end
    end  


  end
end  

Rails.configuration.to_prepare do  

  unless Setting.included_modules.include?(RedmineContacts::Patches::SettingCompatibilityPatch) && (Redmine::VERSION.to_a.first(3).join('.') < '1.3.0')
    Setting.send(:include, RedmineContacts::Patches::SettingCompatibilityPatch)
  end

end
