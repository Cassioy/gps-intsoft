require 'redmine'

require_dependency 'author_hook'

Rails.logger.info 'Starting Author Plugin for Redmine'

Redmine::Plugin.register :author do
    name 'Author box'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Adds box with the author photo, name etc into the sidebar.'
    url 'http://projects.andriylesyuk.com/projects/redmine-author'
    version '0.1.0'

    settings :default => { :author_role_id => nil }, :partial => 'settings/author_role'
end
