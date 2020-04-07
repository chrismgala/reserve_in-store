module Admins
  class ApplicationController < ::ApplicationController
    before_action :authenticate_admin!
    layout 'admins' 
  end
end
