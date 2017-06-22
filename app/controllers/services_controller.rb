class ServicesController < ApplicationController

  def send_zoho
    # render plain: "OK"
    user = Salesman.assigned
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
    changes += "<FL val='Lead Status'>Not Contacted</FL>"
    time = Time.zone.now
    time = time.strftime("%m/%d/%Y %H:%M:%S").to_s
    changes += "<FL val=\"Created Time\">#{time}</FL>"
    changes += "<FL val='Created at'>#{time}</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    base_request + base_xmldata
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    zoho_id = parse_response(check,'Leads')
    data = ":bust_in_silhouette: Owner: #{user.name} \n <https://crm.zoho.com/crm/EntityInfo.do?id=#{zoho_id[:zoho_id]}&module=Leads|#{params[:name]}> \n #{params[:email]}, #{params[:phone]} - #{params[:source]}:#{params[:campaign]}"
    slack_it!(data, 'leads')
    render json: {zoho_id: zoho_id[:zoho_id], owner_id: zoho_id[:owner_id]}.to_json
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
    zoho_data = params[:zoho_id].split(',')
    data = ":spiral_calendar_pad: <https://crm.zoho.com/crm/EntityInfo.do?id=#{zoho_data[0]}&module=#{zoho_data[1]}|#{params[:name]}> \n #{params[:email]}, answer: #{params[:q_a]} #{params[:start_time]}"
    slack_it!(data, 'calendly')
    check = create_event
    if check[:error]
      render status: 500, json: check
    else
      render json: check
    end
  end

  def calendly_cancelled
    base_request = "https://crm.zoho.com/crm/private/json/Calls/searchRecords?newFormat=1&authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi"
    base_xmldata = "&criteria=(Call Result:#{params[:call_id]})"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    activity_id = parse_cancelled(check)
    if activity_id
      base_request = "https://crm.zoho.com/crm/private/json/Calls/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{activity_id}&newFormat=1&xmlData="
      text = "Calendly_cancelled: #{params[:name]} - #{params[:email]} - #{params[:init_date]} - #{params[:call_id]}"
      changes = "<FL val='Call Result'>#{text}</FL>"
      changes += "<FL val='Subject'>#{text}</FL>"
      base_xmldata = "<Calls><row no='1'>#{changes}</row></Calls>"
      request = URI.parse(URI.escape(base_request + base_xmldata))
      check = JSON.parse(Net::HTTP.get(request))
      render json: check.to_json
    else
      render status: 500, json: {error: "No Activity Found in Zoho: #{params[:name]} - #{params[:email]} - #{params[:call_id]} - #{params[:init_date]}"}
    end
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
    @closing_date = params[:closing_date]
    @answers = calculate_answers(params)
    # @answers = 13
    @amount = params[:amount].gsub(",","").to_f
    # @amount = params[:amount]
    @name = params[:name]
    base_request = "https://crm.zoho.com/crm/private/json/Deals/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&wfTrigger=true&id=#{zoho_id}&newFormat=1&xmlData="
    changes = ""
    changes += "<FL val='App Answers'>#{@answers}</FL>"
    # changes += "<FL val='App Attempts'>#{@answers}</FL>"
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
    data = ":trophy: <https://crm.zoho.com/crm/EntityInfo.do?module=Potentials&id=#{zoho_id}|#{@name}> \n #{number_to_currency(@amount, precision: 2)} - #{@closing_date}"
    slack_it!(data, 'answers')
  end

end
