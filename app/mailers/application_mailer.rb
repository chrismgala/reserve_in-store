class ApplicationMailer < ActionMailer::Base
  default from: 'team@reserveinstore.com'
  layout 'mailer'

  def system_contact
    "\"#{system_name}\" <#{system_email}>"
  end

  def team_contact
    "\"#{team_name}\" <#{team_email}>"
  end

  def team_name
    ENV['TEAM_NAME'].presence || 'Reserve In Store Team'
  end

  def team_email
    ENV['TEAM_EMAIL'].presence || 'team@reserveinstore.com'
  end

  def system_name
    ENV['SYSTEM_NAME'].presence || 'Reserve In Store'
  end

  def system_email
    ENV['SYSTEM_EMAIL'].presence || 'team@reserveinstore.com'
  end

end
