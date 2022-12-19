# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
#
initial_frame_ancestors = [:https, "*.myshopify.com", "admin.shopify.com", "app.reserveinstore.com", "*.reserveinstore.com"]
initial_frame_ancestors << "*.ngrok.io" if Rails.env.development?

def current_domain
  @current_domain ||= (params[:shop] && ShopifyApp::Utils.sanitize_shop_domain(params[:shop])) ||
    request.env["jwt.shopify_domain"] ||
    session[:shopify_domain]
end

frame_ancestors = lambda {
  ancestors = []

  if current_domain
    ancestors += [ current_domain, "admin.shopify.com", "app.reserveinstore.com" ]
    ancestors << "*.ngrok.io" if Rails.env.development?
  else
    ancestors += initial_frame_ancestors
  end

  ancestors
}

 Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https
    policy.frame_ancestors(frame_ancestors)
#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
 end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
