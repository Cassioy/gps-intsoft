
require 'redmine_contacts_invoices/hooks/views_layouts_hook'

Rails.configuration.to_prepare do  
  require 'redmine_contacts_invoices/patches/project_patch'
  require 'redmine_contacts_invoices/patches/settings_controller_patch'
end

module RedmineContactsInvoices

  def self.settings() Setting[:plugin_redmine_contacts_invoices] end
    
  def self.invoice_lines_units
    settings[:units].blank? ? [] : settings[:units].split("\n")
  end
  
  def self.available_locales
    Dir.glob(File.join(Redmine::Plugin.find(:redmine_contacts_invoices).directory, 'config', 'locales', '*.yml')).collect {|f| File.basename(f).split('.').first}.collect(&:to_sym)
    # [:en, :de, :fr, :ru]
  end
  
  def self.rate_plugin_installed?
    @@rate_plugin_installed ||= Redmine::Plugin.installed?(:redmine_rate)
  end

  module Hooks
    class ViewLayoutsBaseHook < Redmine::Hook::ViewListener     
      render_on :view_layouts_base_html_head, :inline => "<%= stylesheet_link_tag :contacts_invoices, :plugin => 'redmine_contacts_invoices' %>"
    end   
  end

end

class String
    def to_class
        Kernel.const_get self
    rescue NameError 
        nil
    end

    def is_a_defined_class?
        true if self.to_class
    rescue NameError
        false
    end
end

