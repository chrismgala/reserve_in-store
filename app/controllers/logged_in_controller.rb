class LoggedInController < ShopifyApp::AuthenticatedController
  include Bananastand::AllowsEmbedding
  before_action :load_current_store
  before_action :set_raven_context
  skip_before_action :verify_authenticity_token, if: :jwt_shopify_domain

  helper_method :hide_menu?, :embedded_mode?

  def hide_menu?
    false
  end

  def embedded_mode?
    false
  end

  private

  def require_subscription!
    if @current_store.active? && @current_store.locations.count > 0 && @current_store.subscription.blank?
      redirect_to subscribe_path
      false
    else
      true
    end
  end

  def load_current_store
    @current_store ||= Store.find_by(shopify_domain: current_shopify_domain)
  end

  def current_store; @current_store; end

  ##
  # Sets the raven context to make debugging easier.
  # TODO: In the future as we grow we will have to remove the PII data here like email, name, store URL and store name but for now it's just more convenient to include it.
  def set_raven_context
    if @current_store.present?
      Raven.user_context(store_id: @current_store.try(:id), store_domain: @current_store.try(:shopify_domain), store_name: @current_store.try(:name) )
    end
  end

end
