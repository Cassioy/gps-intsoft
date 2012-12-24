require File.expand_path('../../test_helper', __FILE__)

class InvoicesControllerTest < ActionController::TestCase  
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
 
  # TODO: Test for delete tags in update action
  
  def setup
    RedmineContactsInvoices::TestCase.prepare

    @controller = InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    User.current = nil  
  end
  
  test "should get index" do
    # log_user('admin', 'admin')   
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    
    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:invoices)
    assert_nil assigns(:project)
  end  

  test "should get index in project" do
    # log_user('admin', 'admin')   
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    
    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:invoices)
    assert_not_nil assigns(:project)
  end  

  test "should get index deny user in project" do
    @request.session[:user_id] = 4
    get :index, :project_id => 1
    assert_response :forbidden
  end  
  
  test "should get index with filters" do
    @request.session[:user_id] = 2
    get :index, :status_id => 1
    assert_response :success
    assert_template :index
    assert_select 'div#contact_list td.name.invoice-name a', '1/001'
    assert_select 'div#contact_list td.name.invoice-name a', {:count => 0, :text => '1/002'}
    # assert_select 'div#invoice_list table.list td.number a', {:count => 0, :text => '1/003'}
  end  
  
  test "should get show" do
    # RedmineContactsInvoices.settings[:total_including_tax] = true
    # log_user('admin', 'admin')   
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    Invoice.find(1).save
    
    get :show, :id => 1
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:invoice)
    assert_not_nil assigns(:project)

    assert_select 'div.subject h3', "Domoway - USD 3 321.00"
    assert_select 'div.invoice-lines table.list tr.line-data td.description', "Consulting work"
  end
  
  test "should get show as pdf" do
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    
    get :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:invoice)
    assert_equal 'application/pdf', @response.content_type
  end
  
  test "should get new" do      
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    assert_select 'input#invoice_number'
    assert_select 'textarea#invoice_lines_attributes_0_description'
  end
  
  test "should not get new by deny user" do      
    @request.session[:user_id] = 4
    get :new, :project_id => 1
    assert_response :forbidden
  end 
  
  
  test "should post create" do
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      post :create, "invoice" => {"number"=>"1/005", 
                                  "discount"=>"10", 
                                  "lines_attributes"=>{"0"=>{"tax"=>"10", 
                                                             "price"=>"140.0", 
                                                             "quantity"=>"23.0", 
                                                             "units"=>"products", 
                                                             "_destroy"=>"", 
                                                             "description"=>"Line one"}}, 
                                  "discount_type"=>"0", 
                                  "contact_id"=>"1", 
                                  "invoice_date"=>"2011-12-01", 
                                  "due_date"=>"2011-12-03", 
                                  "description"=>"Test description", 
                                  "currency"=>"GBR", 
                                  "status_id"=>"1"}, 
                    "project_id"=>"ecookbook"
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id
  
    invoice = Invoice.find_by_number('1/005')
    assert_not_nil invoice
    assert_equal 10, invoice.discount
    assert_equal "Line one", invoice.lines.first.description
  end  

  test "should post create with custom fields" do
    field = InvoiceCustomField.create!(:name => 'Test', :is_filter => true, :field_format => 'string')
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      post :create, "invoice" => {"number"=>"1/005", 
                                  "discount"=>"10", 
                                  "lines_attributes"=>{"0"=>{"tax"=>"10", 
                                                             "price"=>"140.0", 
                                                             "quantity"=>"23.0", 
                                                             "units"=>"products", 
                                                             "_destroy"=>"", 
                                                             "description"=>"Line one"}}, 
                                  "discount_type"=>"0", 
                                  "contact_id"=>"1", 
                                  "invoice_date"=>"2011-12-01", 
                                  "due_date"=>"2011-12-03", 
                                  "description"=>"Test description", 
                                  "currency"=>"GBR", 
                                  "status_id"=>"1",
                                  "custom_field_values"=>{"#{field.id}"=>"one"}}, 
                    "project_id"=>"ecookbook"
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id
  
    invoice = Invoice.find_by_number('1/005')
    assert_not_nil invoice
    assert_equal "one", invoice.custom_field_values.last.value
  end    

  test "should not post create by deny user" do
    @request.session[:user_id] = 4
    post :create, :project_id => 1,
        "invoice" => {"number"=>"1/005"}
    assert_response :forbidden
  end 
  
  test "should get edit" do 
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:invoice)
    assert_equal Invoice.find(1), assigns(:invoice)
    assert_select 'textarea#invoice_lines_attributes_0_description', "Consulting work"
  end
  
  test "should put update" do
    @request.session[:user_id] = 1
  
    invoice = Invoice.find(1)
    old_number = invoice.number
    new_number = '2/001'
    
    put :update, :id => 1, :invoice => {:number => new_number}
    assert_redirected_to :action => 'show', :id => '1'
    invoice.reload
    assert_equal new_number, invoice.number 
  end
      
  test "should post destroy" do
    @request.session[:user_id] = 1
    delete :destroy, :id => 1
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.find_by_id(1)
  end    

  test "should bulk_destroy" do
    @request.session[:user_id] = 1
    assert_not_nil Invoice.find_by_id(1)
    delete :bulk_destroy, :ids => [1]
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.find_by_id(1)
  end    

  test "should get context menu" do 
    @request.session[:user_id] = 1
    xhr :get, :context_menu, :back_url => "/projects/ecookbok/invoices", :project_id => 'ecookbook', :ids => ['1', '2']
    assert_response :success
    assert_template 'context_menu'
  end

 
end

