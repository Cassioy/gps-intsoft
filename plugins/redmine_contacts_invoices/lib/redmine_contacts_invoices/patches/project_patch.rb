module RedmineContactsInvoices
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc: 
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          has_many :invoices, :dependent => :destroy 
        end  
      end  
    end
  end
end

unless Project.included_modules.include?(RedmineContactsInvoices::Patches::ProjectPatch)
  Project.send(:include, RedmineContactsInvoices::Patches::ProjectPatch)
end
