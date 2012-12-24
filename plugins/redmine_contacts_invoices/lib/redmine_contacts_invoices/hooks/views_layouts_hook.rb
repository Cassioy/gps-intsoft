module RedmineContactsInvoices
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        return content_tag(:style, "#admin-menu a.invoices { background-image: url('/plugin_assets/redmine_contacts_invoices/images/invoice.png') }".html_safe, :type => 'text/css')
      end
    end
  end
end
