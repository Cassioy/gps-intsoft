class CreateTags < ActiveRecord::Migration
  def self.up
    unless ActsAsTaggableOn::Tag.table_exists? 
      create_table :tags do |t|
        t.column :name, :string
      end
      add_index :tags, :name
    end
    add_column :tags, :color, :integer
    add_column :tags, :created_at, :datetime
    add_column :tags, :updated_at, :datetime
    
    unless ActsAsTaggableOn::Tagging.table_exists?  
      create_table :taggings do |t|
        t.column :tag_id, :integer
        t.column :taggable_id, :integer
        t.column :tagger_id, :integer
        t.column :tagger_type, :string
      
        # You should make sure that the column created is
        # long enough to store the required class names.
        t.column :taggable_type, :string
        t.column :context, :string
      
        t.column :created_at, :datetime
      end
      add_index :taggings, :tag_id
      add_index :taggings, :taggable_id
      add_index :taggings, :taggable_type
      add_index :taggings, :context
    end
    
  end
  
  def self.down
    drop_table :taggings
    drop_table :tags
  end
end


