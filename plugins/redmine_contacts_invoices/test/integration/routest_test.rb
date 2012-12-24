require File.expand_path('../../test_helper', __FILE__)

class RoutingTest < ActionController::IntegrationTest

  test "invoices" do
    # REST actions
    assert_routing({ :path => "/invoices", :method => :get }, { :controller => "invoices", :action => "index" })
    assert_routing({ :path => "/invoices.xml", :method => :get }, { :controller => "invoices", :action => "index", :format => 'xml' })
    assert_routing({ :path => "/invoices/1", :method => :get }, { :controller => "invoices", :action => "show", :id => '1'})
    assert_routing({ :path => "/invoices/1/edit", :method => :get }, { :controller => "invoices", :action => "edit", :id => '1'})
    assert_routing({ :path => "/projects/23/invoices", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23'})
    assert_routing({ :path => "/projects/23/invoices.xml", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23', :format => 'xml'})
    assert_routing({ :path => "/projects/23/invoices.atom", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23', :format => 'atom'})

    assert_routing({ :path => "/invoices.xml", :method => :post }, { :controller => "invoices", :action => "create", :format => 'xml' })

    assert_routing({ :path => "/invoices/1.xml", :method => :put }, { :controller => "invoices", :action => "update", :format => 'xml', :id => "1" })

  end
  

end
