class ApplicationMailer < ActionMailer::Base
  default from: 'team@bananastand.io'
  layout 'mailer'

  def from_system
    email = "noreply@bananastand.io"
    name = "Banana Stand System"
    "#{name} <#{email}>"
  end

  def from_team
    email = "team@bananastand.io"
    name = "Banana Stand Team"
    "#{name} <#{email}>"
  end

end
