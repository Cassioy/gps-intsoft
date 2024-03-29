class ContactsQueriesController < ApplicationController
  unloadable

  before_filter :find_query, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create]

  accept_api_auth :index

  helper :queries
  include QueriesHelper

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = ContactsQuery.scoped({})
    scope = scope.scoped(:conditions => {:type => params[:type]}) if params[:type]
    @query_count = scope.visible.count
    @query_pages = Paginator.new self, @query_count, @limit, params['page']
    @queries = scope.visible.all(:limit => @limit, :offset => @offset, :order => "#{ContactsQuery.table_name}.name")

    respond_to do |format|
      format.html { render :nothing => true }
      format.api
    end
  end

  def new
    @query = ContactsQuery.new
    @query.user = User.current
    @query.project = @project
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    build_query_from_params
  end

  def create
    @query = ContactsQuery.new(params[:query])
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    build_query_from_params
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :query_id => @query
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params[:query]
    @query.project = nil if params[:query_is_for_all]
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    build_query_from_params
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :query_id => @query
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :set_filter => 1
  end

private
  def find_query
    @query = ContactsQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_contacts_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
