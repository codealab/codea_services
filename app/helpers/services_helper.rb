module ServicesHelper

  def search_zoho(email,type)
    base_request = "https://crm.zoho.com/crm/private/json/#{type}/searchRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&criteria=(Email:#{email})"
    request = URI.parse(URI.escape(base_request))
    check = JSON.parse(Net::HTTP.get(request))
    parse_response(check,type)
  end

  def parse_response(check,type)
    if check['response']['nodata'] || check['response']['error']
      false
    else
      response = check['response']['result']['recorddetail']
      unless response.kind_of?(Array)
        zoho_id = response['FL'].first['content']
        owner_id = response['FL'][1]['content']
      else
        zoho_id = response.first['FL'].first['content']
        owner_id = response.first['FL'][1]['content']
      end
      owner_id = /^[0-9]*$/.match(owner_id) ? owner_id : Salesman.actual_id
      {zoho_id: zoho_id, owner_id: owner_id}
    end
  end

  def parse_cancelled(check)
    if check['response']['nodata'] || check['response']['error']
      false
    else
      check['response']['result']['Calls']['row']['FL'].first['content']
    end
  end

  def find_zoho_owner(id,type)
    base_request = "https://crm.zoho.com/crm/private/json/#{type}/getRecordById?&authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{id}"
    request = URI.parse(URI.escape(base_request))
    check = JSON.parse(Net::HTTP.get(request))
    parsed = parse_response(check,type)#[1]
    parsed ? parsed : false
  end

  def parse_salesforceuuid
    zoho = params[:zoho_id].split(',')
    return parse_zoho_mail if zoho.count == 1
    params.update(zoho_id: zoho[0], zoho_type: zoho[1], zoho_owner: zoho[2])
  end

  def parse_zoho_mail
    contact = search_zoho(params[:email],'Contacts')
    if contact
      zoho_id = contact[:zoho_id].is_a?(Array) ? contact[:zoho_id].first : contact[:zoho_id]
      type = "Contacts"
      owner_id = contact[:owner_id]
    else
      lead = search_zoho(params[:email],'Leads')
      if lead
        zoho_id = lead[:zoho_id].is_a?(Array) ? lead[:zoho_id].first : lead[:zoho_id]
        type = "Leads"
        owner_id = lead[:owner_id]
      else
        {error: "No Zoho ID, or no email found. Email: #{params[:email]} Name: #{params[:name]}", email: params[:email]}
      end
    end
    params.update(zoho_id: zoho_id, zoho_type: type, zoho_owner: owner_id)
  end

  def create_call_zoho(zoho_id,zoho_type,zoho_owner,name,start_time,end_time,link,q_a,cancellation,reschedule,event_id)
    # Creo la línea base del API request a Zoho
    base_request = "https://crm.zoho.com/crm/private/json/Calls/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&newFormat=1&xmlData="
    # Genero y concateno una variable con los parametros de la petición
    changes = "<FL val='Subject'>Calendly_new: #{name} - #{start_time.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call Start Time'>#{(start_time - 15.minutes).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Call End Time'>#{(end_time).strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Created at'>#{Time.zone.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    changes += "<FL val='Description'>#{q_a}: #{link}</FL>"
    changes += "<FL val='Call Result'>#{event_id}</FL>"
    changes += "<FL val='whichCall'>ScheduleCall</FL>"
    # # el formato en que se manda el owner depende del modulo
    if zoho_type == 'Contacts'
      changes += "<FL val='CONTACTID'>#{zoho_id}</FL>"
      changes += "<FL val='SEMODULE'>Contacts</FL>"
    else
      changes += "<FL val='LEADID'>#{zoho_id}</FL>"
      changes += "<FL val='SEMODULE'>Leads</FL>"
    end
    changes += "<FL val='SEID'>#{zoho_id}</FL>"
    changes += "<FL val='SMOWNERID'>#{zoho_owner}</FL>"
    # Agregamos los cambios al objeto Calls de XML
    base_xmldata = "<Calls><row no='1'>#{changes}</row></Calls>"
    # Update a los datos del Contacto o Leads
    update_contact(zoho_type,zoho_id,start_time,link,cancellation,reschedule)
    # Generamos la URI para hacer el request
    request = URI.parse(URI.escape(base_request + base_xmldata))
    # Enviamos la URI vía GET y parseamos a JSON los resultados
    check = JSON.parse(Net::HTTP.get(request))
  end



  # params[:zoho_id],params[:zoho_type],params[:zoho_owner],params[:name],params[:email],DateTime.parse(params[:start_time]),DateTime.parse(params[:end_time]),params[:link],params[:q_a],params[:cancellation],params[:reschedule],params[:event_id]
  def create_event
    params[:zoho_id] ? parse_salesforceuuid : parse_zoho_mail
    if params[:error]
       {error: "No Zoho ID, or no email found. Email: #{params[:email]} Name: #{params[:name]}", email: params[:email]}
    else
      create_call_zoho(params[:zoho_id],params[:zoho_type],params[:zoho_owner],params[:name],DateTime.parse(params[:start_time]),DateTime.parse(params[:end_time]),params[:link],params[:q_a],params[:cancellation],params[:reschedule],params[:event_id])
    end
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
