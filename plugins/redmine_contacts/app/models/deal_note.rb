class DealNote < Note
  unloadable
  belongs_to :deal, :foreign_key => :source_id 
end  
