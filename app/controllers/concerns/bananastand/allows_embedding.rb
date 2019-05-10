module Bananastand
  module AllowsEmbedding
    extend ActiveSupport::Concern

    included do
      after_action :enable_embedded_mode
    end

    def enable_embedded_mode
      response.headers['P3P'] = 'CP="Not used"'
      response.headers.except! 'X-Frame-Options'
      response.default_headers.delete('X-Frame-Options')
    end

  end
end
