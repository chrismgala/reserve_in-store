class UsersController < LoggedInController

  ##
  # POST /users
  def create
    user = User.new(params.fetch(:user, {}).permit(:name, :email).merge(store: @current_store))

    if user.save
      redirect_to stores_settings_url
    else
      ForcedLogger.log(user.errors.inspect)
      redirect_to stores_setup_url, flash: { error: "A problem occurred with your signup details. Please contact our support team for help."}
    end
  end

  def hide_menu?
    params[:action] == 'setup'
  end

end
