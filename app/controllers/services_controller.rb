class ServicesController < ApplicationController
  def send_zoho
    base_request = "https://crm.zoho.com/crm/private/json/Leads/insertRecords?authtoken=#{ENV['ZOHO_TOKEN']}&scope=crmapi&xmlData="
    changes = ""
    changes += "<FL val='Last Name'>#{params["name"]}</FL>"
    changes += "<FL val='Email'>#{params["email"]}</FL>"
    changes += "<FL val='Phone'>#{params["phone"]}</FL>"
    changes += "<FL val='Description'>#{params["description"]}</FL>"
    changes += "<FL val='Lead Source'>#{params["source"]}</FL>"
    changes += "<FL val='Lead Medium'>#{params["medium"]}</FL>"
    changes += "<FL val='Campaign'>#{params["campaign"]}</FL>"
    changes += "<FL val='Offer'>#{params["offer"]}</FL>"
    time = Time.now - 3.hours
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
    puts "Update check"
    p check
    render json: check.to_json
  end
end
