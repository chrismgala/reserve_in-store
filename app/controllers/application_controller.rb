class ApplicationController < ActionController::Base
  before_action :set_host
  after_action :add_csp_headers

  CONTENT_SECURITY_POLICY_PARTS = [
    "frame-ancestors",
    "'self'",
    "*.fera.ai",
    "fera.ai",
    "*.fera.to",
    "*.shopify.com",
    "*.myshopify.com",
    "*.mybigcommerce.com",
    "*.bigcommerce.com",
    "*.wix.com",
    "admin.shopify.com",
    "reserveinstore.com",
    "*.reserveinstore.com",
    "extraverification.com",
    "*.extraverification.com",
  ].compact.freeze

  helper_method :embedded_mode?

  def embedded_mode?
    false
  end

  private

  def set_host
    @host = params[:host]
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(admins)
    admin_root_path
  end

  def add_csp_headers
    response.headers["Content-Security-Policy"] = CONTENT_SECURITY_POLICY_PARTS.join(' ')
  end
end
