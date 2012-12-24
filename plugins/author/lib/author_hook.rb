class AuthorHook  < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('author', :plugin => 'author')
    end

    render_on :view_layouts_base_sidebar, :partial => 'author/profile'

end
