Rails.application.routes.draw do
  root 'services#root'
  get 'send_zoho' => 'services#send_zoho'
  get 'update_zoho' => 'services#update_zoho'
  get 'mail_campaign' => 'services#mail_campaign'
  post 'calendly' => 'services#calendly'
end
