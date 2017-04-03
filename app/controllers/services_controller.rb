class ServicesController < ApplicationController
  def send_zoho
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
      changes += "<FL val='Mail Campaign Log'>#{new_campaign}</FL>"
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
