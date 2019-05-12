class ApplicationMailer < ActionMailer::Base
  default from: 'team@fera.ai'
  layout 'mailer'

  def from_system
    "#{ENV['SYSTEM_NAME']} <#{ENV['SYSTEM_EMAIL']}>"
  end

  def from_team
    "#{ENV['TEAM_NAME']} <#{ENV['TEAM_EMAIL']}>"
  end

end
