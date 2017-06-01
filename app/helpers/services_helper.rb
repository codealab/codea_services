module ServicesHelper

  def search_zoho(email,type)
    base_request = "https://crm.zoho.com/crm/private/json/#{type}/searchRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&criteria=(Email:#{email})"
    request = URI.parse(URI.escape(base_request))
    check = JSON.parse(Net::HTTP.get(request))
    parse_response(check,type)
  end

  def parse_response(check,type)
    if check['response']['nodata']
      false
    else
      response = check['response']['result'][type]['row']
      unless response.kind_of?(Array)
        zoho_id = response['FL'].first['content']
        owner_id = response['FL'][1]['content']
      else
        zoho_id = response.first['FL'].first['content']
        owner_id = response.first['FL'][1]['content']
      end
      [zoho_id,owner_id]
    end
  end

  def create_event(id,name,mail,start_dt,end_dt,link,answer,cancellation,reschedule,event)
    if id
      type = "Leads"
    else
      contact = search_zoho(mail,'Contacts')
      lead = search_zoho(mail,'Leads')
      if contact
        contact_id = contact[0].is_a?(Array) ? contact[0].first : contact[0]
        owner_id = contact[1]
      elsif lead
        lead_id = lead[0].is_a?(Array) ? lead[0].first : lead[0]
        owner_id = lead[1]
      else
        "ERROR"
      end
      type = contact_id ? 'Contacts' : (lead_id ? 'Leads' : false)
      id = contact_id ? contact_id : lead_id
    end
    base_request = "https://crm.zoho.com/crm/private/json/Calls/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&newFormat=1&xmlData="
    changes = "<FL val='Subject'>Calendly_new: #{name} - #{start_dt.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call Start Time'>#{(start_dt - 15.minutes).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call End Time'>#{(end_dt).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    if type == 'Contacts'
      changes += "<FL val='#{type.upcase[0..-2]}ID'>#{id}</FL>"
    else
      changes += "<FL val='SEID'>#{id}</FL>"
      changes += "<FL val='SEMODULE'>Leads</FL>"
    end
    changes += "<FL val='Created at'>#{Time.zone.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Description'>#{answer}: #{link}</FL>"
    changes += "<FL val='Call Result'>#{event}</FL>"
    changes += "<FL val='SMOWNERID'>#{owner_id}</FL>"
    changes += "<FL val='whichCall'>ScheduleCall</FL>"
    #owner
    base_xmldata = "<Calls><row no='1'>#{changes}</row></Calls>"
    p "Update contact"
    p update_contact(type,id,start_dt,link,cancellation,reschedule)
    request = URI.parse(URI.escape(base_request + base_xmldata))
    p check = JSON.parse(Net::HTTP.get(request))
  end

  def update_contact(type,id,start,link,cancellation,reschedule)
    base_request = "https://crm.zoho.com/crm/private/json/#{type}/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&id=#{id}&xmlData="
    changes = "<FL val='Calendly Hangouts'>#{link}</FL>"
    changes += "<FL val='Calendly DateTime'>#{start.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Calendly Cancellation'>#{cancellation}</FL>"
    changes += "<FL val='Calendly Reschedule'>#{reschedule}</FL>"
    base_xmldata = "<#{type}><row no='1'>#{changes}</row></#{type}>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
  end

  def parse_zoho_params(params)
    changes = Hash.new
    params.each do |k,v|
      field = case k
        when 'name' then 'Last Name'
        when 'source' then 'Lead Source'
        when 'medium' then 'Lead Medium'
        when 'campaign' then 'Campaign'
        else k.capitalize
      end
      changes[field] = v
    end
    changes
  end

  def calculate_answers(params)
    correct_answers = {question1: 'Alto nivel, interpretado, y orientado a objetos.', question2: '"Hola mundo"', question3: '2.7', question4: 'true', question5: 'Hash', question6: 'title = "Yo soy el título"', question7: 'ID = 5', question8: 'Son elementos que relacionan los valores de una o más variables o constantes para manipularlos.', question9: 'Exponencial', question10: '25', question11: 'Comparan valores entre sí', question12: '->', question13: '# Comentando'}
    answers = 0
    correct_answers.each { |k,v| answers += 1 if v == params[k] }
    answers
  end

end
