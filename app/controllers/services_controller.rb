class ServicesController < ApplicationController

  def send_zoho
    p "PARAMS",params
    # render plain: "OK"
    p user = Salesman.assigned
    base_request = "https://crm.zoho.com/crm/private/json/Leads/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&duplicateCheck=2&newFormat=1&xmlData="
    changes = ""
    changes += "<FL val='Lead Owner'>#{user.email}</FL>"
    changes += "<FL val='Last Name'>#{params["name"]}</FL>"
    changes += "<FL val='Email'>#{params["email"]}</FL>"
    changes += "<FL val='Phone'>#{params["phone"]}</FL>"
    changes += "<FL val='Description'>#{params["description"]}</FL>"
    changes += "<FL val='Lead Source'>#{params["source"]}</FL>"
    changes += "<FL val='Lead Medium'>#{params["medium"]}</FL>"
    changes += "<FL val='Campaign'>#{params["campaign"]}</FL>"
    changes += "<FL val='Offer'>#{params["offer"]}</FL>"
    time = Time.zone.now
    time = time.strftime("%m/%d/%Y %H:%M:%S").to_s
    changes += "<FL val=\"Created Time\">#{time}</FL>"
    changes += "<FL val='Created at'>#{time}</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    p base_request + base_xmldata
    request = URI.parse(URI.escape(base_request + base_xmldata))
    p check = JSON.parse(Net::HTTP.get(request))
    p zoho_id = check["response"]["result"]["recorddetail"]["FL"].first["content"]
    render json: {id: zoho_id}.to_json
  end

  def update_zoho
    base_request = "https://crm.zoho.com/crm/private/json/Leads/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{params["zoho_id"]}&newFormat=1&xmlData="
    changes = ""
    changes += "<FL val='Knowledge'>#{params["knowledge"]}</FL>" if params["knowledge"] != ""
    changes += "<FL val='Age'>#{params["age"]}</FL>" if params["age"] != ""
    changes += "<FL val='Gender'>#{params["gender"]}</FL>" if params["gender"] != ""
    changes += "<FL val='Activity'>#{params["activity"]}</FL>" if params["activity"] != ""
    changes += "<FL val='Profession'>#{params["profession"]}</FL>" if params["profession"] != ""
    changes += "<FL val='Profession Type'>#{params["profession_type"]}</FL>" if params["profession_type"] != ""
    changes += "<FL val='Residence'>#{params["residence"]}</FL>" if params["residence"] != ""
    changes += "<FL val='Salary'>#{params["salary"]}</FL>" if params["salary"] != ""
    changes += "<FL val='Payment Method'>#{params["payment_method"]}</FL>" if params["payment_method"] != ""
    changes += "<FL val='Completed Advance Form'>true</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    render json: check.to_json
  end

  def mail_campaign
    url = params[:url]
    user_type = params['user_type'] == "Leads" ? "Leads" : "Contacts"
    user_request = "https://crm.zoho.com/crm/private/json/#{user_type}/getRecordById?authtoken=#{ENV['ZOHO_TOKEN']}&id=#{params["zoho_id"]}&scope=crmapi&newFormat=2"
    user_check = JSON.parse(Net::HTTP.get(URI.parse(URI.escape(user_request))))
    unless user_check["response"]["nodata"]
      old_campaign = user_check["response"]["result"][user_type]["row"]["FL"].select { |field| field["val"] == "Mail Campaign Log" }.first["content"]
      campaign = "Campaña: #{params["campaign"]} \n"
      new_campaign = old_campaign == "null" ? campaign : campaign + "\n" + old_campaign
      email = (params['email'] && params['email'] != "" ) ? params['email'] : nil
      phone = (params['phone'] && params['phone'] != "" ) ? params['phone'] : nil
      base_request = "https://crm.zoho.com/crm/private/json/#{user_type}/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{params["zoho_id"]}&xmlData="
      changes = ""
      changes += "<FL val='#{user_type[0..-2]} Status'>Interested Again</FL>"
      changes += "<FL val='Interested Again'>#{Time.zone.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
      changes += "<FL val='Mail Campaign'>#{campaign}</FL>"
      changes += "<FL val='Mail Campaign Log'>#{new_campaign} #{Time.zone.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
      changes += "<FL val='Email'>#{email}</FL>" if email
      changes += "<FL val='Phone'>#{phone}</FL>" if phone
      base_xmldata = "<#{user_type}><row no='1'>#{changes}</row></#{user_type}>"
      request = URI.parse(URI.escape(base_request + base_xmldata))
      check = JSON.parse(Net::HTTP.get(request))
      render json: check.to_json
    else
      render plain: "ERROR"
    end
  end

  def calendly
    puts "Calendly"
    pp params
    # render plain: "Exito"
    response = create_event(params[:zoho_id],params[:name],params[:email],DateTime.parse(params[:start_time]),DateTime.parse(params[:end_time]),params[:link],params[:q_a],params[:cancellation],params[:reschedule],params[:event_id])
    render plain: response
  end

  def calendly_cancelled
    base_request = "https://crm.zoho.com/crm/private/json/Calls/searchRecords?newFormat=1&authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi"
    base_xmldata = "&criteria=(Call Result:#{params[:call_id]})"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    activity_id = check['response']['result']['Calls']['row']['FL'].first['content']
    base_request = "https://crm.zoho.com/crm/private/json/Calls/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{activity_id}&newFormat=1&xmlData="
    text = "calendly_cancelled: #{params[:invitee]} - #{params[:init_date]}"
    changes = "<FL val='Call Result'>#{text}</FL>"
    changes += "<FL val='Subject'>#{text}</FL>"
    base_xmldata = "<Calls><row no='1'>#{changes}</row></Calls>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    render json: check.to_json
  end

  def payments
    changes = ""
    type = params[:zoho_type] ? params[:zoho_type] : 'Leads'
    if params[:zoho_id]
      changes += "<FL val='Interested Again'>#{Time.zone.now.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    end
    updates = parse_zoho_params(params)
    updates.each { |k,v| changes += "<FL val='#{k}'>#{v}</FL>"}
    base_request = params[:zoho_id] != "" ? "https://crm.zoho.com/crm/private/json/#{type}/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{params[:zoho_id]}&xmlData=" : "https://crm.zoho.com/crm/private/json/Leads/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&duplicateCheck=2&newFormat=1&xmlData="
    base_xmldata = "<#{type}><row no='1'>#{changes}</row></#{type}>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    render json: check
  end

  def app_answers
    zoho_id = params[:zoho_id]
    # answers = params[:answers].to_i
    @answers = calculate_answers(params)
    @closing_date = params[:closing_date]
    @amount = params[:amount].to_f
    @name = params[:name]
    base_request = "https://crm.zoho.com/crm/private/json/Deals/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{zoho_id}&newFormat=1&xmlData="
    changes = ""
    changes += "<FL val='App Answers'>#{@answers}</FL>"
    base_xmldata = "<Deals><row no='1'>#{changes}</row></Deals>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    @title = if @answers > 12
      "¡Felicidades! Todas tus respuestas son correctas"
    elsif @answers > 9
      "Muy bien, contestaste la mayoría de las respuestas correctamente"
    elsif @answers > 5
      "Tienes algunas respuestas correctas"
    else
      "La mayoría de tus respuestas son incorrectas"
    end
  end

end
