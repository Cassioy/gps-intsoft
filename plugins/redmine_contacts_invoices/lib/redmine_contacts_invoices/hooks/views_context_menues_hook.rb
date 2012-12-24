module RedmineContactsInvoices
  module Hooks
    class ViewsContextMenuesHook < Redmine::Hook::ViewListener     
      # :view_issues_context_menu_end, {:issues => @issues, :can => @can, :back => @back }) %>
      render_on :view_issues_context_menu_end, :partial => "context_menues/invoices_issues" 
      render_on :view_time_entries_context_menu_end, :partial => "context_menues/invoices_time_entries" 
    end   
  end
end
