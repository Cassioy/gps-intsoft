class InvoiceReport < Prawn::Document
  
  include Redmine::I18n
  
  # unloadable
  
  # def initialize(invoice)
  #   @invoice = invoice
  #   
  # end

  
  def to_pdf(invoice)
    fonts_path = "#{RAILS_ROOT}/vendor/plugins/redmine_contacts_invoices/lib/fonts/"
    font_families.update(
           "FreeSans" => { :bold => fonts_path + "FreeSansBold.ttf",
                           :italic => fonts_path + "FreeSansOblique.ttf",
                           :bold_italic => fonts_path + "FreeSansBoldOblique.ttf",
                           :normal => fonts_path + "FreeSans.ttf" })    

    font "FreeSans"
    
    text l(:label_invoice), :style => :bold, :size => 30
    lines = invoice.lines.map do |line|
      [
        line.position,
        line.description,
        line.quantity,
        line.price,
        line.total
      ]
    end
    lines.insert(0,[l(:field_invoice_line_position),
                   l(:field_invoice_line_description),
                   l(:field_invoice_line_quantity),
                   l(:field_invoice_line_price),
                   l(:field_invoice_line_total) ])  

    table lines, 
      :row_colors => ["FFFFFF", "DDDDDD"],
      :header => true
      
    render
  end
end
