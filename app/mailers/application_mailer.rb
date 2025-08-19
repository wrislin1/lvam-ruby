class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.smtp[:from]
  layout "mailer"
end
