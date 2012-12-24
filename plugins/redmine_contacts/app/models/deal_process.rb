class DealProcess < ActiveRecord::Base
  unloadable          
  
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :deal
  scope :visible, lambda {|*args| { :include => {:deal => :project},
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_deals)} }   

end
