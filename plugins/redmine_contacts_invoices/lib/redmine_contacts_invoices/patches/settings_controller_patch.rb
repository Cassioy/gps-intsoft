module RedmineContactsInvoices
  module Patches    

    module SettingsControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          helper :invoices
        end
      end
    end
    
  end
end

unless SettingsController.included_modules.include?(RedmineContactsInvoices::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineContactsInvoices::Patches::SettingsControllerPatch)
end
