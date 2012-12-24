class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.string :number
      t.datetime :invoice_date
      t.decimal :discount, :precision => 10, :scale => 2, :default => 0, :null => false
      t.integer :discount_type, :default => 0, :null => false
      t.text :description
      t.datetime :due_date
      t.string :language
      t.string :currency, :size => 3
      t.integer :status_id
      t.integer :contact_id
      t.integer :project_id
      t.integer :assigned_to_id
      t.integer :author_id
      t.timestamps
    end
    add_index :invoices, :contact_id 
    add_index :invoices, :project_id
    add_index :invoices, :status_id
    add_index :invoices, :assigned_to_id
    add_index :invoices, :author_id
  end

  def self.down
    drop_table :invoices
  end
end
