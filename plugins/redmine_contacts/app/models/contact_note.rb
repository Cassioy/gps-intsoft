class ContactNote < Note
  unloadable
  belongs_to :contact, :foreign_key => :source_id 
  
  acts_as_searchable :columns => ["#{table_name}.content"],  
                     :include => [:contact => :projects], 
                     :project_key => "#{Project.table_name}.id", 
                     :permission => :view_contacts,            
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"
                     
  acts_as_activity_provider :type => 'contacts',               
                            :permission => :view_contacts,  
                            :author_key => :author_id,
                            :find_options => {:include => [:contact => :projects], :conditions => {:source_type => 'Contact'} }
  
  scope :visible, lambda {|*args| {:include => [:contact => :projects],
                                         :conditions => Contact.allowed_to_condition(args.first || User.current, :view_contacts)+
                                                        " AND (#{DealNote.table_name}.source_type = 'Contact')"}}
end
