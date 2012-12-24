require File.expand_path('../../test_helper', __FILE__)  

class ContactTest < ActiveSupport::TestCase
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

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
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


  # Replace this with your real tests.
  test "Should get first by email" do
    emails = ["marat@mail.ru", "domoway.mail.ru"]
    assert_equal 2, Contact.find_by_emails(emails).count
  end

  test "Should get first by second email" do
    emails = ["marat@mail.com"]
    assert_equal 1, Contact.find_by_emails(emails).count
  end

  
end
