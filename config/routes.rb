Rails.application.routes.draw do
  get 'send_zoho' => 'services#send_zoho'
  get 'update_zoho' => 'services#update_zoho'
end
