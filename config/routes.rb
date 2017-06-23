Rails.application.routes.draw do
  root 'services#root'
  get 'send_zoho', to: 'services#send_zoho'
  get 'update_zoho', to: 'services#update_zoho'
  get 'mail_campaign', to: 'services#mail_campaign'
  post 'calendly_zoho', to: 'services#calendly'
  post 'calendly_cancelled', to: 'services#calendly_cancelled'
  get 'payments_zoho', to: 'services#payments'
  get 'app_answers', to: 'services#app_answers'
  get 'slack_it', to: 'services#slack_it'
  get 'codeatalks', to: 'services#codeatalks'
  get 'codeatalks_confirm', to: 'services#codeatalks_confirm'
end
