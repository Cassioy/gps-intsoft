class CreateInvoiceLines < ActiveRecord::Migration
  def self.up
    create_table :invoice_lines do |t|
      t.integer  :invoice_id
      t.integer  :position
      t.decimal  :quantity, :precision => 10, :scale => 2, :default => 1, :null => false
      t.string   :description, :limit => 512
      t.decimal  :tax, :precision => 10, :scale => 2 
      t.decimal  :price, :precision => 10, :scale => 2, :default => 0, :null => false
      t.string   :units
      t.timestamps
    end
    add_index :invoice_lines, :invoice_id 
  end

  def self.down
    drop_table :invoice_lines
  end
end
