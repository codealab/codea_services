class ServicesController < ApplicationController
  def send_zoho
    puts "WTF"*100
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
    time = Time.now.strftime("%m/%d/%Y %H:%M:%S")
    changes += "<FL val='Created at'>#{time}</FL>"
    base_xmldata = "<Leads><row no='1'>#{changes}</row></Leads>"
    puts "Request"
    puts base_request + base_xmldata
    request = URI.parse(URI.escape(base_request + base_xmldata))
    puts "request"
    p request
    check = JSON.parse(Net::HTTP.get(request))
    puts "check"
    p check
    zoho_id = check["response"]["result"]["recorddetail"]["FL"].first["content"]
    puts "Zoho id"
    p zoho_id
    hash = {id: zoho_id , response: {result: true, params: params}}
    puts "Hash"
    p hash
    render json: hash.to_json
  end
end
