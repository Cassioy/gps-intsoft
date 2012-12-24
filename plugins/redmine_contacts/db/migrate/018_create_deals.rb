class CreateDeals < ActiveRecord::Migration
  def self.up
    create_table :deals do |t|
      t.string   :name
      t.text     :background
      t.integer  :currency
      t.integer  :duration
      t.decimal  :price
      t.integer  :price_type
      t.integer  :project_id
      t.integer  :author_id
      t.integer  :assigned_to_id
      t.integer  :status_id,      :default => 0, :null => false
      t.integer  :contact_id
      t.integer  :category_id
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :deals, :contact_id
    add_index :deals, :project_id
    add_index :deals, :status_id
    add_index :deals, :author_id
    add_index :deals, :category_id
    
  end

  def self.down
    drop_table :deals
  end
end
