class ServicesController < ApplicationController
  def send_zoho
    p params
    JSON.parse({response: {result: true}})
  end
end
