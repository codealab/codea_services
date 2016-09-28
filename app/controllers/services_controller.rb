class ServicesController < ApplicationController
  def send_zoho
    p params
    render json: JSON.parse({response: {result: true}})
  end
end
