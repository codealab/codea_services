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
    time = Time.now -5.hours
    changes += "<FL val='Created at'>#{time.strftime("%m/%d/%Y %H:%M:%S")}</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    request = URI.parse(URI.escape(base_request + base_xmldata))
    check = JSON.parse(Net::HTTP.get(request))
    zoho_id = check["response"]["result"]["recorddetail"]["FL"].first["content"]
    hash = {id: zoho_id , response: {result: true, params: params}}
    render json: hash.to_json
  end
  def update_zoho

  end
end
