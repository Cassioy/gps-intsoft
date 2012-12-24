class InvoiceTimeEntriesController < ApplicationController
  unloadable
  
  before_filter :find_project_by_project_id, :only => [:create, :new]
  
  include InvoicesHelper
  
  def new
    invoice = Invoice.new
    total_time = TimeEntry.sum(:hours, :conditions => {:issue_id => params[:issues_ids]}, :group => :activity_id)
    total_time.first
    total_time.each do |k, v|
      scope = Issue.scoped(:include => :time_entries,  :conditions => {:id => params[:issues_ids]})
      scope = scope.scoped(:conditions => ["#{TimeEntry.table_name}.activity_id = ?", k])
      issues = scope.all
      invoice.lines << invoice.lines.new(:description => issues.map(&:subject).join("\n"), :quantity => total_time[k])
    end  
    redirect_to :controller => "invoices", :action => "new", :copy_from => invoice, :project_id => @project    
  end

end
