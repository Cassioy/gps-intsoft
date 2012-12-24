class Note < ActiveRecord::Base   
  unloadable
  
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :source, :polymorphic => true
  
  # added as a quick fix to allow eager loading of the polymorphic association for multiprojects
  
  validates_presence_of :source, :author, :content

 
  # TODO: Notifications should be ported
  after_create :send_mails  
  
  acts_as_customizable
  acts_as_attachable :view_permission => :view_contacts,  
                     :delete_permission => :edit_contacts   
                    
  acts_as_event :title => Proc.new {|o| "#{l(:label_note_for)}: #{o.source.name}"}, 
                :type => "issue-note", 
                :url => Proc.new {|o| {:controller => 'notes', :action => 'show', :note_id => o.id }},
                :description => Proc.new {|o| o.content}      
  


                                   
                            # :joins => "LEFT JOIN #{Contact.table_name} ON #{Note.table_name}.source_type='Contact' AND #{Contact.table_name}.id = #{Note.table_name}.source_id " +
                            #           # "JOIN contacts_projects ON contacts_projects.contact_id = #{Contact.table_name}.id " +
                            #           # "JOIN #{Project.table_name} ON contacts_projects.project_id = #{Project.table_name}.id" }
                            #           Contact.projects_joins.join(' ') }    
                                                               
                            # :joins => "LEFT JOIN #{Deal.table_name} ON #{Note.table_name}.source_type='Deal' AND #{Deal.table_name}.id = #{Note.table_name}.source_id " +
                            #           "LEFT JOIN #{Project.table_name} ON #{Deal.table_name}.project_id = #{Project.table_name}.id"}
   
  cattr_accessor :note_types
  @@note_types = {:email => 0, :call => 1, :meeting => 2}
  cattr_accessor :cut_length
  @@cut_length = 1000
  
  def self.note_types
    @@note_types
  end
  
  def self.available_authors(prj=nil)     
    options = {}
    options[:select] = "DISTINCT #{User.table_name}.*"   
    options[:joins] = "JOIN #{Note.table_name} nnnn ON nnnn.author_id = #{User.table_name}.id" 
    options[:order] = "#{User.table_name}.lastname, #{User.table_name}.firstname"       
    prj.nil? ? User.active.find(:all, options) : prj.users.active.find(:all, options)
  end  
  
  def project 
     self.source.respond_to?(:project) ? self.source.project : nil  
  end
             
  def editable_by?(usr, prj=nil)
    prj ||= @project || self.project    
    usr && (usr.allowed_to?(:delete_notes, prj) || (self.author == usr && usr.allowed_to?(:delete_own_notes, prj))) 
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def destroyable_by?(usr, prj=nil)  
    prj ||= @project || self.project    
    usr && (usr.allowed_to?(:delete_notes, prj) || (self.author == usr && usr.allowed_to?(:delete_own_notes, prj)))
  end
       
  
  private
  
  def send_mails   
    if self.source.class == Contact && !self.source.is_company
      parent = Contact.find_by_first_name(self.source.company)
    end
    Mailer.contacts_note_added(self, parent).deliver
  end
  

end
                    

