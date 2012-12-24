require File.expand_path('../../../test_helper', __FILE__)
# require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class ApiTest::InvoicesTest < ActionController::IntegrationTest
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', 
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :notes,
                             :roles,
                             :enabled_modules,
                             :tags,
                             :taggings,
                             :contacts_queries])   



    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', 
                          [:invoices,
                           :invoice_lines])

  def setup
    Setting.rest_api_enabled = '1'
    RedmineContactsInvoices::TestCase.prepare
  end

  test "GET /invoices.xml" do
    # Use a private project to make sure auth is really working and not just
    # only showing public issues.
    ActiveSupport::TestCase.should_allow_api_authentication(:get, "/invoices.xml")
     # test "should contain metadata" do
      get '/invoices.xml', {}, credentials('admin')
      
      assert_tag :tag => 'invoices',
        :attributes => {
          :type => 'array',
          :total_count => assigns(:invoices_count),
          :limit => 25,
          :offset => 0
        }

  end

  # Issue 6 is on a private project
  # context "/invoices/2.xml" do
  #   should_allow_api_authentication(:get, "/invoices/2.xml")
  # end

  test "POST /invoices.xml" do
    ActiveSupport::TestCase.should_allow_api_authentication(:post,
                                    '/invoices.xml',
                                    {:invoice => {:project_id => 1, :number => 'INV/TEST-1'}},
                                    {:success_code => :created})
  
      assert_difference('Invoice.count') do
        post '/invoices.xml', {:invoice => {:project_id => 1, :number => 'INV/TEST-1', :contact_id => 1, :status_id => 1, :invoice_date => Date.today}}, credentials('admin')
      end

      invoice = Invoice.first(:order => 'id DESC')
      assert_equal 'INV/TEST-1', invoice.number
  
      assert_response :created
      assert_equal 'application/xml', @response.content_type
      assert_tag 'invoice', :child => {:tag => 'id', :content => invoice.id.to_s}
  end

  # Issue 6 is on a private project
  test "PUT /invoices/1.xml" do
      @parameters = {:invoice => {:number => 'NewNumber'}}
    
      ActiveSupport::TestCase.should_allow_api_authentication(:put,
                                    '/invoices/1.xml',
                                    {:invoice => {:number => 'NewNumber'}},
                                    {:success_code => :ok})
  
      assert_no_difference('Invoice.count') do
        put '/invoices/1.xml', @parameters, credentials('admin')
      end
  
      invoice = Invoice.find(1)
      assert_equal "NewNumber", invoice.number
    
  end
  
end
