class AddInvoicesFields < ActiveRecord::Migration
  def self.up
    add_column :invoices, :subject, :string
    add_column :invoices, :amount, :decimal, :precision => 10, :scale => 2, :default => 0, :null => false

    Invoice.find(:all).each do |invoice|
      invoice.calculate_amount
      invoice.save
    end

  end 


  def self.down
    remove_column :invoices, :subject
    remove_column :invoices, :amount
  end
end
