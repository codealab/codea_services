class ServicesController < ApplicationController
  def send_zoho
    p params
    render json: {response: {result: true, params: params}}.to_json
  end
end
