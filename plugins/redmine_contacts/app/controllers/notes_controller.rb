class NotesController < ApplicationController
  unloadable
  default_search_scope :notes
  # before_filter :find_model_object
  before_filter :find_project_by_project_id, :except => :show    
  before_filter :find_optional_project, :only => :show
  before_filter :find_note, :only => [:show, :edit, :update, :destroy]    
  before_filter :authorize, :except => [:index]

  helper :attachments
  helper :notes  
  helper :contacts
  helper :custom_fields
  
  def show   
    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def new
    find_note_source
    @note = Object.const_get(@note_source.class.name + 'Note').new()
    @note.source = @note_source
  end

  def edit 
    (render_403; return false) unless @note.editable_by?(User.current, @project)
  end  
  
  def update
    if @note.update_attributes(params[:note])
      Attachment.attach_files(@note, params[:note_attachments])    
      render_attachment_warning_if_needed(@note)
      flash[:notice] = l(:notice_successful_update)     
      redirect_to :action => "show", :project_id => @note.source.project, :note_id => @note
    else
      render "edit", :project_id => params[:project_id], :note_id => @note  
    end
    
  end

  def add_note   
    find_note_source   
    @note = @note_source.notes.new(params[:note])
    @note.author = User.current   
    @note.created_on = @note.created_on + Time.now.hour.hours + Time.now.min.minutes + Time.now.sec.seconds if @note.created_on
    if @note.save    
      Attachment.attach_files(@note, params[:note_attachments])    
      render_attachment_warning_if_needed(@note)
      flash[:notice] = l(:label_note_added)
      respond_to do |format|
        format.js {flash.discard}   
        format.html {redirect_to :back}
      end
    else
        # TODO При render если коммент не добавился то тут появялется ошибка из-за того что не передаются данные для paginate
      redirect_to :back  
    end                   
  end    
  
  def destroy 
    (render_403; return false) unless @note.destroyable_by?(User.current, @project) 
    @note.destroy
    respond_to do |format|
      format.js 
      format.html {redirect_to :action => 'show', :project_id => @project, :id => @note.source }
    end
    
    # redirect_to :action => 'show', :project_id => @project, :id => @contact
  end
  
  
  private
  
  def find_note
    @note = Note.find(params[:note_id])
    @project ||= @note.project  
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_note_source
    klass = Object.const_get(params[:source_type].camelcase)
    # return false unless klass.respond_to?('watched_by')
    @note_source = klass.find(params[:source_id])
  end

end
