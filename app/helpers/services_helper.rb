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

  def create_event(name,mail,start_dt,end_dt,link)
    contact = search_zoho(mail,'Contacts')
    lead = search_zoho(mail,'Leads')
    if contact
      contact_id = contact[0]
      owner_id = contact[1]
    else
      lead_id = lead[0]
      owner_id = lead[1]
    end
    type = contact_id ? 'Contacts' : (lead_id ? 'Leads' : false)
    base_request = "https://crm.zoho.com/crm/private/json/Calls/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&newFormat=1&xmlData="
    changes = "<FL val='Subject'>Calendly: #{name} - #{start_dt.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call Start Time'>#{(start_dt - 15.minutes).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call End Time'>#{(end_dt).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    id = contact_id ? contact_id : lead_id
    changes += "<FL val='#{type.upcase[0..-2]}ID'>#{id}</FL>"
    changes += "<FL val='Created at'>#{Time.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Description'>#{link}</FL>"
    changes += "<FL val='SMOWNERID'>#{owner_id}</FL>"
    changes += "<FL val='whichCall'>ScheduleCall</FL>"
    #owner
    base_xmldata = "<Calls><row no='1'>#{changes}</row></Calls>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
  end

end
