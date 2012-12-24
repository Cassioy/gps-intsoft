module InvoicesHelper
  # require 'reports/invoice_report' 
  # include ActionView::Helpers::NumberHelper
  include Redmine::I18n
  include CustomFieldsHelper
  require "open-uri"
  
  def default_user_rate(user, project)
    if RedmineContactsInvoices.rate_plugin_installed? && RedmineContactsInvoices.settings[:use_rate_plugin] 
       Rate.find(:first, 
                 :conditions => {:project_id => project.id, :user_id => user.id},
                 :order => "#{Rate.table_name}.date_in_effect ASC").try(:amount).to_s
    else
      ''
    end   
  end

  def invoice_status_tag(invoice)
    status_tag = content_tag(:span, invoice_status_name(invoice.status_id)) 
    content_tag(:span, status_tag, :class => "deal-status invoice-status tags #{invoice_status_name(invoice.status_id, true).to_s}")
  end  
  
  def contact_custom_fields
    if "ContactCustomField".is_a_defined_class?
      ContactCustomField.find(:all, :conditions => ["#{ContactCustomField.table_name}.field_format = 'string' OR #{ContactCustomField.table_name}.field_format = 'text'"]).map{|f| [f.name, f.id.to_s]}
    else
      []
    end
  end
  
  def invoice_collection_for_currencies_select
    ["USD", "EUR", "GBR", "RUB", "CZK", "CDN", "DKK", "AUD", "INR", "CAD", "SEK", "CHF", "JPY", "CNY", "TL", "UAH"].collect{|c| [c, c]}
  end

  def invoice_lang_options_for_select(has_blank=true)
    (has_blank ? [["(auto)", ""]] : []) +
      RedmineContactsInvoices.available_locales.collect{|lang| [ ll(lang.to_s, :general_lang_name), lang.to_s]}.sort{|x,y| x.last <=> y.last }
  end
  
  def invoice_avaliable_locales_hash
    Hash[*invoice_lang_options_for_select.collect{|k, v| [v.blank? ? "default" : v, k]}.flatten]
  end

  def collection_invoice_status_names
    [[:draft, Invoice::DRAFT_INVOICE], 
     [:sent, Invoice::SENT_INVOICE], 
     [:paid, Invoice::PAID_INVOICE]]
  end

  def collection_invoice_statuses
    [[l(:label_invoice_status_draft), Invoice::DRAFT_INVOICE], 
     [l(:label_invoice_status_sent), Invoice::SENT_INVOICE], 
     [l(:label_invoice_status_paid), Invoice::PAID_INVOICE]]
  end

  def collection_for_invoice_status_for_select(status_id)
    collection = collection_invoice_statuses.map{|s| [s[0], s[1].to_s]}
    collection.push [l(:label_invoice_overdue), "d"]
    collection.insert 0, [l(:label_open_issues), "o"]
    collection.insert 0, [l(:label_all), ""]
    
    options_for_select(collection, status_id)
    
  end

  def label_with_currency(label, currency)
    l(label).mb_chars.capitalize.to_s + (currency.blank? ? '' : " (#{currency})")
  end  
  
  def stat_sum(sum_hash)
    sum_hash.any? ? sum_hash.map{|k, v| "#{k} #{invoice_price(v)}"}.join("<br/>").html_safe : invoice_price(0)    
  end
  
  def invoice_status_name(status, code=false)
    return (code ? "draft" : l(:label_invoice_status_draft)) unless collection_invoice_statuses.map{|v| v[1]}.include?(status)

    status_data = collection_invoice_statuses.select{|s| s[1] == status }.first[0]
    status_name = collection_invoice_status_names.select{|s| s[1] == status}.first[0]
    return (code ? status_name : status_data)
  end

  def collection_for_discount_types_select
    [:percent, :amount].each_with_index.collect{|l, index| [l("label_invoice_#{l.to_s}".to_sym), index]}
  end
  
  def invoice_price(price)
    ActionController::Base.helpers.number_to_currency(price, 
        :unit => '', 
        :separator => RedmineContactsInvoices.settings[:decimal_separator] || '.', 
        :delimiter => RedmineContactsInvoices.settings[:thousands_delimiter] || ' ', 
        :precision => 2)
    # ActionController::Base.helpers.number_with_delimiter(price, :delimiter => ' ', :precision => 2)
  end
 
  def invoice_number_format(number)
    ActionController::Base.helpers.number_with_delimiter(number, 
        :separator => RedmineContactsInvoices.settings[:decimal_separator] || '.', 
        :delimiter => RedmineContactsInvoices.settings[:thousands_delimiter] || ' ')
  end
  
  def link_to_remove_fields(name, f, options={})
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", options)
  end
  
  def discount_label(invoice)
    "#{l(:field_invoice_discount)}#{' (' + invoice_number_format(invoice.discount_rate).to_s + '%)' if invoice.discount_type == 0 }"
  end
  
  def link_to_add_fields(name, f, association, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new 
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end  
    link_to_function(name, "add_fields(this, '#{association}', '#{escape_javascript(fields)}')", options={})
  end
  
  def invoices_sum_to_currency(invoices)
    invoices_sum = invoices.group_by{|l| l.currency}.map{|k, v| [k, v.sum{|l| l.amount}] }
    invoices_sum.map{|c| content_tag(:span, [c[0], invoice_price(c[1].to_f)].join(' ') , :style => "white-space: nowrap;")}.join('<br/>')  
  end
  
  
  def retrieve_invoices_query
    # debugger
    # params.merge!(session[:deals_query])
    # session[:deals_query] = {:project_id => @project.id, :status_id => params[:status_id], :category_id => params[:category_id], :assigned_to_id => params[:assigned_to_id]}

    if  params[:status_id] || !params[:contact_id].blank? || !params[:assigned_to_id].blank? || !params[:period].blank? 
      session[:invoices_query] = {:project_id => (@project ? @project.id : nil), 
                                  :status_id => params[:status_id], 
                                  :contact_id => params[:contact_id], 
                                  :period => params[:period],
                                  :assigned_to_id => params[:assigned_to_id]}
    else
      if api_request? || params[:set_filter] || session[:invoices_query].nil? || session[:invoices_query][:project_id] != (@project ? @project.id : nil)
        session[:invoices_query] = {}
      else
        params.merge!(session[:invoices_query])
      end
    end
  end
  
  def is_no_filters
    (params[:status_id] == 'o' && params[:assigned_to_id].blank? && (params[:period].blank? || params[:period] == 'all') && (params[:due_date].blank? || params[:due_date] == 'all') && params[:contact_id].blank?)
  end
  
  def is_date?(str)
    temp = str.gsub(/[-.\/]/, '')
    ['%m%d%Y','%m%d%y','%M%D%Y','%M%D%y'].each do |f|
      begin
        return true if Date.strptime(temp, f)
      rescue
           #do nothing
      end
    end
  end
  
  def due_days(invoice)
    return "" if invoice.due_date.blank? || invoice.due_date.to_date >= Date.today || invoice.status_id != Invoice::SENT_INVOICE 
    content_tag(:span, " (#{l(:label_invoice_days_late, :days => (Date.today - invoice.due_date.to_date).to_s)})", :class => "overdue-days")
  end
  
  def get_contact_extra_field(contact)
    field_id = RedmineContactsInvoices.settings[:contact_extra_field]
    return "" if field_id.blank?
    contact.custom_values.find_by_custom_field_id(field_id)
  end


  def invoice_to_pdf(invoice, type)
    invoice_to_pdf_classic(invoice)
  end
  
  def invoice_to_pdf_classic(invoice)
    set_language_if_valid(invoice.language || User.current.language)
    
    
    # InvoiceReport.new.to_pdf(invoice)
    pdf = Prawn::Document.new(:info => {
        :Title => "#{l(:label_invoice)} - #{invoice.number}",
        :Author => User.current.name,
        :Producer => RedmineContactsInvoices.settings[:company_name],
        :Subject => "Invoice",
        :Keywords => "invoice",
        :Creator => RedmineContactsInvoices.settings[:company_name],
        :CreationDate => Time.now,
        :TotalAmount => invoice_price(invoice.amount),
        :TaxAmount => invoice_price(invoice.tax),
        :Discount => invoice_price(invoice.discount_amount)
        },
        :margin => [50, 50, 60, 50])
    contact = invoice.contact || Contact.new(:first_name => '[New client]', :address => '[New client address]', :phone => '[phone]')

    fonts_path = "#{Rails.root}/plugins/redmine_contacts_invoices/lib/fonts/"
    pdf.font_families.update(
           "FreeSans" => { :bold => fonts_path + "FreeSansBold.ttf",
                           :italic => fonts_path + "FreeSansOblique.ttf",
                           :bold_italic => fonts_path + "FreeSansBoldOblique.ttf",
                           :normal => fonts_path + "FreeSans.ttf" })    

    # pdf.stroke_bounds
    pdf.font("FreeSans", :size => 9)
    # pdf.font("Times-Roman")
    pdf.default_leading -5
    
    # pdf.move_down(10)
    pdf.text RedmineContactsInvoices.settings[:company_name], :style => :bold, :size => 18
    # pdf.move_down(5)
    pdf.text RedmineContactsInvoices.settings[:company_representative] if RedmineContactsInvoices.settings[:company_representative]
    pdf.text_box "#{RedmineContactsInvoices.settings[:company_info]}", 
      :at => [0, pdf.cursor], :width => 140


    # pdf.move_down(30)

    # pdf.text l(:label_invoice), :style => :bold, :align => :right, :size => 30, :color => 'ffffff'
    # pdf.define_grid(:columns => 2, :rows => 2, :gutter => 10)
    # pdf.grid.show_all
    # 
    # 
    
    invoice_data = [
      [l(:field_invoice_number) + ":",
      invoice.number],
      [l(:field_invoice_date) + ":",
      format_date(invoice.invoice_date)]]
    
    invoice.custom_values.each do |custom_value| 
      if !custom_value.value.blank? && custom_value.custom_field.is_for_all?
        invoice_data << [custom_value.custom_field.name + ":",
                         show_value(custom_value)]
      end
    end
    
    invoice_data << [l(:label_invoice_bill_to) + ":", 
                     "#{contact.name}
                     #{contact.address}
                     #{get_contact_extra_field(contact)}"]
      
    # , :borders => []
    
    pdf.bounding_box [pdf.bounds.width - 250, pdf.bounds.height + 10], :width => 250 do
      # pdf.stroke_bounds
      pdf.fill_color "cccccc"
      pdf.text l(:label_invoice), :align => :right, :style => :bold, :size => 30
      # pdf.text_box l(:label_invoice), :at => [pdf.bounds.width - 100, pdf.bounds.height + 10],
      #              :style => :bold, :size => 30, :color => 'cccccc', :align => :right, :valign => :top,
      #              :width => 100, :height => 50,
      #              :overflow => :shrink_to_fit

      pdf.fill_color "000000"

    # pdf.grid([1,0], [1,1]).bounding_box do
      pdf.table invoice_data, :cell_style => {:padding => [-3, 5, 3, 5], :borders => []} do |t|
        t.columns(0).font_style = :bold
        # t.columns(0).text_color = "990000"
        t.columns(0).width = 100
        t.columns(0).align = :right
        t.columns(1).width = 150
      end
    end
    
    pdf.move_down(30)
    
    classic_table(pdf, invoice)
    
  
    if RedmineContactsInvoices.settings[:bill_info]
      pdf.text RedmineContactsInvoices.settings[:bill_info]
    end
    
    pdf.move_down(10)
    
    pdf.text invoice.description
      

    status_stamp(pdf, invoice) 

    pdf.number_pages "<page>/<total>", {:at => [pdf.bounds.right - 150, -10], :width => 150,
              :align => :right} if pdf.page_number > 1

    pdf.repeat(lambda{ |pg| pg > 1}) do
       pdf.draw_text "##{invoice.number}", :at => [0, -20]
    end      
    
    pdf.render 
  end

  def status_stamp(pdf, invoice)
    case invoice.status_id
    when Invoice::DRAFT_INVOICE
      stamp_text = "DRAFT"
      stamp_color = "993333"
    when Invoice::PAID_INVOICE
      stamp_text = "PAID"
      stamp_color = "1e9237"
    else  
      stamp_text = ""
      stamp_color = "1e9237"
    end

    stamp_text_width = pdf.width_of(stamp_text, :font => "Times-Roman", :style => :bold, :size => 120)
    pdf.create_stamp("draft") do
      pdf.rotate(30, :origin => [0, 50]) do
        pdf.fill_color stamp_color
        pdf.font("Times-Roman", :style => :bold, :size => 120) do
          pdf.transparent(0.08) {pdf.draw_text stamp_text, :at => [0, 0]}
        end
        pdf.fill_color "000000"
      end
    end

    pdf.stamp_at "draft", [(pdf.bounds.width / 2) - stamp_text_width / 2, (pdf.bounds.height / 2) ] unless stamp_text.blank?
  end
  
  def classic_table(pdf, invoice)
    lines = invoice.lines.map do |line|
      [
        line.position,
        line.description,
        "x#{invoice_number_format(line.quantity)}",
        line.units,
        invoice_price(line.price),
        invoice_price(line.total)
      ]
    end
    lines.insert(0,[l(:field_invoice_line_position),
                   l(:field_invoice_line_description),
                   l(:field_invoice_line_quantity),
                   l(:field_invoice_line_units),
                   label_with_currency(:field_invoice_line_price, @invoice.currency),
                   label_with_currency(:label_invoice_total, @invoice.currency) ])  
    lines << ['']               
    lines << ['', '', '', '', l(:label_invoice_sub_amount) + ":", invoice_price(invoice.sub_amount)]  if invoice.discount_amount > 0 || (invoice.tax > 0 && !invoice.total_with_tax?)
    
    @invoice.tax_groups.each do |tax_group|
      lines << ['', '', '', '', "#{l(:label_invoice_tax)} (#{invoice_number_format(tax_group[0])}%):", invoice_price(tax_group[1])]              
    end if @invoice.tax > 0 
    
    lines << ['', '', '', '', discount_label(invoice) + ":", "-" + invoice_price(invoice.discount_amount)] if invoice.discount_amount > 0

    lines << ['', '', '', '', label_with_currency(:label_invoice_total, @invoice.currency) + ":", invoice_price(invoice.amount)]               
    
    pdf.table lines, :width => pdf.bounds.width, :cell_style => {:padding => [-3, 5, 3, 5]}, :header => true do |t|
      # t.cells.padding = 405
      t.columns(0).width = 20
      t.columns(2).align = :center
      t.columns(2).width = 40
      t.columns(3).align = :center
      t.columns(3).width = 50
      t.columns(4..5).align = :right
      t.columns(4..5).width = 90
      t.row(0).font_style = :bold
      t.row(0).align = :center
      # t.row(0).background_color = 'cccccc'
      
      max_width =  t.columns(2).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
      t.columns(2).width = max_width if max_width < 100 
      
      max_width =  t.columns(3).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
      t.columns(3).width = max_width if max_width < 100 
      
      max_width =  t.columns(4).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
      t.columns(4).width = max_width if max_width < 120 
      
      max_width =  t.columns(5).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
      t.columns(5).width = max_width if max_width < 120 
      
      
      t.row(invoice.lines.count + 2).padding = [5, 5, 3, 5]

      t.row(invoice.lines.count + 2..invoice.lines.count + 6).borders = []
      t.row(invoice.lines.count + 2..invoice.lines.count + 6).font_style = :bold
    end
  end  
  

  def generate_invoice_number
    result = ""
    format = RedmineContactsInvoices.settings[:invoice_number_format]
    if format
      result = format.gsub(/%%ID%%/, "%02d" % (Invoice.last.try(:id).to_i + 1).to_s)
      result = result.gsub(/%%YEAR%%/, Date.today.year.to_s)
      result = result.gsub(/%%MONTH%%/, "%02d" % Date.today.month.to_s)
      result = result.gsub(/%%DAY%%/, "%02d" % Date.today.day.to_s)      
      result = result.gsub(/%%DAILY_ID%%/, "%02d" % (Invoice.count(:conditions => {:invoice_date => Date.today.to_time}) + 1).to_s) 
    end  
    
  end
  
  

end
