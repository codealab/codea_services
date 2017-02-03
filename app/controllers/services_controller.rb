class ServicesController < ApplicationController
  def send_zoho
    user = Salesman.assigned
    base_request = "https://crm.zoho.com/crm/private/json/Leads/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&xmlData="
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
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    zoho_id = check["response"]["result"]["recorddetail"]["FL"].first["content"]
    render json: {id: zoho_id}.to_json
  end
  def update_zoho
    base_request = "https://crm.zoho.com/crm/private/json/Leads/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{params["zoho_id"]}&xmlData="
    changes = ""
    changes += "<FL val='Knowledge'>#{params["knowledge"]}</FL>"
    changes += "<FL val='Age'>#{params["age"]}</FL>"
    changes += "<FL val='Gender'>#{params["gender"]}</FL>"
    changes += "<FL val='Activity'>#{params["activity"]}</FL>"
    changes += "<FL val='Profession'>#{params["profession"]}</FL>"
    changes += "<FL val='Profession Type'>#{params["profession_type"]}</FL>"
    changes += "<FL val='Residence'>#{params["residence"]}</FL>"
    changes += "<FL val='Availability'>#{params["availability"]}</FL>"
    changes += "<FL val='Payment Method'>#{params["payment_method"]}</FL>"
    changes += "<FL val='Completed Advance Form'>true</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    render json: check.to_json
  end
  def mail_campaign
    user_type = params['user_type'] == "Leads" ? "Leads" : "Contacts"
    user_request = "https://crm.zoho.com/crm/private/json/#{user_type}/getRecordById?authtoken=#{ENV['ZOHO_TOKEN']}&id=#{params["zoho_id"]}&scope=crmapi&newFormat=2"
    user_check = JSON.parse(Net::HTTP.get(URI.parse(URI.escape(user_request))))
    unless user_check["response"]["nodata"]
      old_notes = user_check["response"]["result"][user_type]["row"]["FL"].select { |field| field["val"] == "Mail Campaign" }.first["content"]
      notes = "Campaña: #{params["campaign"]} \n Notas: #{params["notes"]} \n" + ("-" * 50)
      new_notes = old_notes == "null" ? notes : notes + "\n" + old_notes
      email = (params['email'] && params['email'] != "" ) ? params['email'] : nil
      phone = (params['phone'] && params['phone'] != "" ) ? params['phone'] : nil
      base_request = "https://crm.zoho.com/crm/private/json/#{user_type}/updateRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&id=#{params["zoho_id"]}&xmlData="
      changes = ""
      changes += "<FL val='Mail Campaign'>#{new_notes}</FL>"
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
end
