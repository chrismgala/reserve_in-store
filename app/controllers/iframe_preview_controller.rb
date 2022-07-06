class IframePreviewController < ApplicationController
  before_action :load_current_store

  ##
  # Used by the template editors to provide previews of the components that are being built.
  # GET /iframe_preview
  def index
    render layout: false
  end

  private

  def load_current_store
    @current_store ||= Store.find_by(shopify_domain: params[:store])
  end

  def current_store; @current_store; end
end
