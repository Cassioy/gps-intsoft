class DealStatus < ActiveRecord::Base
  unloadable
  
  has_and_belongs_to_many :projects
  has_many :deals, :foreign_key => 'status_id', :dependent => :nullify
end
