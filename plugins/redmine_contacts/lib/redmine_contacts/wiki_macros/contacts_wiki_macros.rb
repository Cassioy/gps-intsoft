module RedmineContacts
  module WikiMacros
    
    Redmine::WikiFormatting::Macros.register do
      desc "thumbnails"
      macro :thumbnails do |obj, args|
        return "" if obj.blank?
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size > 2  
        
        size = ""
        size = args.first if args.any?
        regexp = args[1] if args.any? && args[1]
        options[:size] = size.blank? ? "100" : size  
        options[:class] = "contacts_thumbnail"
        options[:regexp] = regexp unless regexp.blank?

        s = '<style type="text/css"> 
        img.contacts_thumbnail {
          border: 1px solid #D7D7D7;
          padding: 4px; 
          margin: 4px;
          vertical-align: middle;   
          background: white;
        } 
        </style>'  
        
        s << contacts_thumbnails(obj, options) 
        content_tag(:p, s) if !s.blank?
      end  

      desc "Contact Description Macro" 
      macro :contact_plain do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end 
        link_to_source(contact) if contact
      end  

      desc "Contact avatar"
      macro :contact_avatar do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end 
        link_to avatar_to(contact, :size => "32"),  contact_url(contact), :id => "avatar", :title => contact.name if contact
      end  

      desc "Contact with avatar"
      macro :contact do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end  
        contact_tag(contact) if contact
      end  

      desc "Deal"
      macro :deal do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        deal = Deal.visible.find(args.first)                                 
        s = ''
        s << avatar_to(deal, :size => "16") + " "
        s << link_to(deal.full_name, polymorphic_url(deal)) + " "
        s << content_tag('span', 
                         h(deal.status), 
                         :style => "background-color:#{deal.status.color_name};color:white;padding: 3px 4px;font-size: 10px;white-space: nowrap;margin-right: 4px;", :class => "deal-status") if deal.status
      end  


    end  

  end
end
