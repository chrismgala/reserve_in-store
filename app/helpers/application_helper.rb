module ApplicationHelper
  def current_store; @current_store; end
  
  def app_version
    @app_version ||= Rails.env.development? ? "v#{Time.now.to_f}" : ENV["HEROKU_RELEASE_VERSION"]
  end
  
  def global_js_vars
    "<script>
  var AUTH_TOKEN = '#{form_authenticity_token}';
  var DEV_MODE = #{!Rails.env.production?};
  var OFFLINE_MODE = #{ENV["OFFLINE_MODE"].to_bool};
  var APP_VERSION = '#{app_version}';
</script>".html_safe
  end

  def meta_description
    "Reserve In-store"
  end

  def title_prefix
    "Reserve In-Store"
  end
end
