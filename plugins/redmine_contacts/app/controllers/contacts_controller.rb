class ContactsController < ApplicationController
  unloadable    
  
  Mime::Type.register "text/x-vcard", :vcf    
  Mime::Type.register "application/vnd.ms-excel", :xls  
  
  default_search_scope :contacts    
  
  before_filter :find_contact, :only => [:show, :edit, :update, :destroy]  
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :only => [:show, :edit, :update, :create, :new, :destroy]
  before_filter :find_optional_project, :only => [:index, :contacts_notes] 
   
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy 
  
  helper :attachments
  helper :contacts  
  include ContactsHelper
  helper :watchers  
  helper :deals
  helper :notes    
  helper :custom_fields
  include CustomFieldsHelper
  helper :context_menus unless Redmine::VERSION.to_s < '1.4'
  include WatchersHelper
  helper :sort
  include SortHelper
  helper :queries
  helper :contacts_queries
  include ContactsQueriesHelper
  include NotesHelper
  
  def index   
    retrieve_contacts_query
    sort_init(@query.sort_criteria.empty? ? [['last_name', 'asc'], ['first_name', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf', 'xls'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end
      @contacts_count = @query.contact_count
      @contacts_pages = Paginator.new self, @contacts_count, @limit, params['page']
      @offset ||= @contacts_pages.current.offset
      @contact_count_by_group = @query.contact_count_by_group
      @contacts = @query.contacts(:include => [:projects, :tags, :avatar],
                              :search => params[:search],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit) 

      @filter_tags = @query.filters["tags"] && @query.filters["tags"][:values] && @query.filters["tags"][:values].map{|tag| ActsAsTaggableOn::Tag.find_by_name(tag) }
      
      respond_to do |format|   
        format.html do
          last_notes
          @tags = Contact.available_tags(:project => @project) 
          render :partial => RedmineContacts.list_partial, :layout => false if request.xhr?
        end
        format.api
        format.atom { render_feed(@contacts, :title => "#{@project || Setting.app_title}: #{l(:label_contact_plural)}") }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'contacts/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end  
  end

  def show   
    scope = @contact.issues
    scope = scope.open unless RedmineContacts.settings[:show_closed_issues]
    @contact_issues_count = scope.visible.count
    @contact_issues = scope.visible.find(:all, :order => "#{Issue.table_name}.status_id, #{Issue.table_name}.due_date DESC, #{Issue.table_name}.updated_on DESC", :limit => 10)   
    

    source_id_cond = @contact.is_company ? Contact.order_by_name.find_all_by_company(@contact.first_name).map(&:id) << @contact.id : @contact.id 
    @note = ContactNote.new  
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 30,
                                    :conditions => {:source_id  => source_id_cond,  
                                                   :source_type => 'Contact'},
                                    :include => [:attachments],               
                                    :order => "created_on DESC" 

    respond_to do |format|
      format.js if request.xhr?  
      format.html { @contact.viewed }  
      format.api
      format.atom { render_feed(@notes, :title => "#{@contact.name || Setting.app_title}: #{l(:label_note_plural)}")  }
      format.vcf { send_data(contact_to_vcard(@contact), :filename => "#{@contact.name}.vcf", :type => 'text/x-vcard;', :disposition => 'attachment') }            
    end
  end
  

  def edit    
  end

  def update  
    @contact.tags.clear
    if @contact.update_attributes(params[:contact])
      flash[:notice] = l(:notice_successful_update)     
      attach_avatar  
      respond_to do |format|
        format.html { redirect_to :action => "show", :project_id => params[:project_id], :id => @contact }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render "edit", :project_id => params[:project_id], :id => @contact  }
        format.api  { render_validation_errors(@contact) }
      end
    end
  end

  def destroy
    if @contact.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    redirect_to :action => "index", :project_id => params[:project_id]
  end
  
  def new  
    @duplicates = []
    @contact = Contact.new  
    @contact.attributes = params[:contact] if params[:contact] && params[:contact].is_a?(Hash)
  end

  def create
    params[:contact].delete(:project_id)
    @contact = Contact.new(params[:contact])
    @contact.projects << @project 
    @contact.author = User.current
    if @contact.save
      flash[:notice] = l(:notice_successful_create)
      attach_avatar  
      respond_to do |format|  
        format.html { redirect_to (params[:continue] ?  {:action => "new", :project_id => @project} : {:action => "show", :project_id => @project, :id => @contact} )}
        format.api  { render :action => 'show', :status => :created, :location => contact_url(@contact) } 
      end
    else 
      respond_to do |format|      
        format.api  { render_validation_errors(@contact) }   
        format.html { render :action => "new" }
      end
    end
  end

  def contacts_notes   
    unless request.xhr?  
      @tags = Contact.available_tags(:project => @project) 
    end  
    # @notes = Comment.find(:all, 
    #                            :conditions => { :commented_type => "Contact", :commented_id => find_contacts.map(&:id)}, 
    #                            :order => "updated_on DESC")  
   
    contacts = find_contacts(false)
    
    joins = " "
    joins << " LEFT OUTER JOIN #{Contact.table_name} ON #{Note.table_name}.source_id = #{Contact.table_name}.id AND #{Note.table_name}.source_type = 'Contact' "
    cond = "(1 = 1) " 
    cond << "and (#{Contact.table_name}.id in (#{contacts.any? ? contacts.map(&:id).join(', ') : 'NULL'})"
    cond << " )"
    cond << " and (LOWER(#{Note.table_name}.content) LIKE '%#{params[:search_note].downcase}%')" if params[:search_note] and request.xhr?
    cond << " and (#{Note.table_name}.author_id = #{params[:note_author_id]})" if !params[:note_author_id].blank?
    cond << " and (#{Note.table_name}.type_id = #{params[:type_id]})" if !params[:type_id].blank?

                                                                                
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 20, 
                                    :joins => joins,      
                                    :conditions => cond, 
                                    :order => "created_on DESC"   
    @notes.compact!   
    
    
    respond_to do |format|   
      format.html { render :partial => "notes/notes_list", :layout => false, :locals => {:notes => @notes, :notes_pages => @notes_pages} if request.xhr?} 
      format.xml { render :xml => @notes }  
      format.csv { send_data(notes_to_csv(@notes), :type => 'text/csv; header=present', :filename => 'notes.csv') }
      format.atom { render_feed(@notes, :title => "#{l(:label_note_plural)}")  }
    end
  end    
  

  def context_menu 
    @project = Project.find(params[:project_id]) unless params[:project_id].blank? 
    @contacts = Contact.visible.all(:conditions => {:id => params[:selected_contacts]})
    @contact = @contacts.first if (@contacts.size == 1)
    @can = {:edit => (@contact && @contact.editable?) || (@contacts && @contacts.collect{|c| c.editable?}.inject{|memo,d| memo && d}),  
            :create_deal => (@project && User.current.allowed_to?(:edit_deals, @project)),  
            :delete => @contacts.collect{|c| c.deletable?}.inject{|memo,d| memo && d},
            :send_mails => @contacts.collect{|c| c.send_mail_allowed? && !c.emails.first.blank?}.inject{|memo,d| memo && d}
            }   
            
    # @back = back_url        
    render :layout => false  
  end   
  
  def bulk_destroy    
    @contacts = Contact.deletable.find_all_by_id(params[:ids])
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    @contacts.each(&:destroy)
    redirect_to :action => "index", :project_id => params[:project_id]
  end
  
  
private      
  def attach_avatar
    if params[:contact_avatar]    
      params[:contact_avatar][:description] = 'avatar'     
      @contact.avatar.destroy if @contact.avatar 
      Attachment.attach_files(@contact, {"1" => params[:contact_avatar]})  
      render_attachment_warning_if_needed(@contact)    
    end
  end

  def last_notes(count=5)    
    # @last_notes = find_contacts(false).find(:all, :include => :notes, :limit => count,  :order => 'notes.created_on DESC').map{|c| c.notes}.flatten.first(count)
    scope = ContactNote.scoped({})
    scope = scope.scoped(:conditions => ["#{Project.table_name}.id = ?", @project.id]) if @project
   
    @last_notes = scope.visible.find(:all, 
                                     :limit => count,
                                     :order => "#{ContactNote.table_name}.created_on DESC")
    # @last_notes = []                            
  end
  
  def find_contact  
    @contact = Contact.find(params[:id])   
    @project = (@contact.projects.visible.find(params[:project_id]) rescue false) if params[:project_id]
    @project ||= @contact.project 
    # if !(params[:project_id] == @project.identifier)
    #   params[:project_id] = @project.identifier     
    #   redirect_to params
    # end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
  def find_contacts(pages=true)   
    @tag = ActsAsTaggableOn::TagList.from(params[:tag]).map{|tag| ActsAsTaggableOn::Tag.find_by_name(tag) } unless params[:tag].blank? 
    
    scope = Contact.scoped({})
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.job_title = ?", params[:job_title]]) unless params[:job_title].blank? 
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.assigned_to_id = ?", params[:assigned_to_id]]) unless params[:assigned_to_id].blank? 
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.is_company = ?", params[:query]]) unless (params[:query].blank? || params[:query] == '2' || params[:query] == '3')   
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.author_id = ?", User.current]) if params[:query] == '3'
    
    case params[:query] 
      when '2' then scope = scope.order_by_creation
      when '3' then scope = scope.order_by_creation 
      else scope = scope.order_by_name
    end     
    
    scope = scope.in_project(@project.id) if @project  

    params[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } if !params[:search].blank? 
    scope = scope.visible
    
    scope = scope.tagged_with(params[:tag]) if !params[:tag].blank? 
    scope = scope.tagged_with(params[:notag], :exclude => true) if !params[:notag].blank? 
    
    @contacts_count = scope.count
    @contacts = scope
    
    if pages    
      page_size = params[:page_size].blank? ? 20 : params[:page_size].to_i
      @contacts_pages = Paginator.new(self, @contacts_count, page_size, params[:page])     
      @offset = @contacts_pages.current.offset  
      @limit =  @contacts_pages.items_per_page 
       
      @contacts = @contacts.scoped :include => [:tags, :avatar], :limit  => @limit, :offset => @offset
      
      fake_name = @contacts.first.name if @contacts.length > 0
    end
    @contacts

  end  
  
  # Filter for bulk issue operations
  def bulk_find_contacts
    @contacts = Deal.find_all_by_id(params[:id] || params[:ids], :include => :project)
    raise ActiveRecord::RecordNotFound if @contact.empty?
    if @contacts.detect {|contact| !contact.visible?}
      deny_access
      return
    end
    @projects = @contacts.collect(&:projects).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
  def parse_params_for_bulk_contact_attributes(params)
    attributes = (params[:contact] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end
  

  def find_project
    project_id = (params[:contact] && params[:contact][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
end
