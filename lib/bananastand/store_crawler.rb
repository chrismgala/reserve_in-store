module Bananastand
  class StoreCrawler < StoreAdapters::BaseStoreAdapter

    class << self
      def mechanize
        @mechanize ||= Mechanize.new do |agent|
          agent.open_timeout = 10.seconds
          agent.read_timeout = 10.seconds
        end
      end
    end

    ##
    # @param url [String|NilClass] If provided gets you the HTML content of the URl cached for 1 day. If not provided just looks at the root URL for the current store.
    # @return [String]
    def cached_html(url = nil)
      url = store.url if url.nil?
      return nil if url.blank?
      return nil if ENV['OFFLINE_MODE'].to_bool

      Rails.cache.fetch("bananastand/stores/#{store.id}/store_crawler/cached_html", expires_in: 1.day) do
        result = read_url(store.url)
        if result.nil?
          nil
        else
          result.content.to_s
        end
      end
    end

    ##
    # Gets you all the CSS content from the store, cached for 1 day
    # @return [String] If an error occurs, the error is logged and reported silently and an empty string is returned
    def cached_stylesheet_contents
      Rails.cache.fetch("bananastand/stores/#{store.id}/store_crawler/cached_stylesheets/v2", expires_in: 1.hour) do
        Nokogiri::HTML(cached_html).css('link[type="text/css"],[rel=\"stylesheet\"]').map do |stylesheet|
          next unless stylesheet['href'].to_s.downcase.include?('.css')

          "/*********** FILE BEGIN: #{stylesheet['href']} ***********/\n" +
            download_stylesheet_content(stylesheet['href']).to_s +
            "\n/*********** FILE END: #{stylesheet['href']} ***********/\n"
        end.join("\n")
      end
    rescue => e
      error(e, sentry: false)
      ''
    end
    
    ##
    # Fetches the content of a CSS stylesheet provided.
    # @param [String] URL to the stylesheet we want content for.
    # @return [String]
    def download_stylesheet_content(url)
      return nil if url.blank?

      url = "https:#{url}" if url[0..1] == '//'

      Timeout::timeout(2) do
        content = HTTParty.get(URI.parse(URI.encode(url)))
        return nil if content.include?('<html')
        content
      end
    rescue Timeout::Error, OpenURI::HTTPError, Net::HTTPClientError, Net::HTTPServerError, Mechanize::ResponseCodeError, SocketError, Net::OpenTimeout, OpenSSL::SSL::SSLError, Net::HTTP::Persistent::Error => e
      if options[:raise_errors]
        raise(e)
      else
        warn "StoreCrawler failed to access stylesheet URL #{url}: #{e.inspect}"
        nil
      end
    end

    def read_url(url = nil)
      url = store.url if url.nil?
      return nil if url.blank? || /\A(http|https):\/\/\z/ =~ url

      Timeout::timeout(10) do
        self.class.mechanize.get(URI.parse(URI.encode(url)))
      end
    rescue Timeout::Error, OpenURI::HTTPError, Net::HTTPClientError, Net::HTTPServerError, Mechanize::ResponseCodeError, SocketError, Net::OpenTimeout, OpenSSL::SSL::SSLError, Net::HTTP::Persistent::Error => e
      if options[:raise_errors]
        raise(e)
      else
        error(e, sentry: false)
        nil
      end
    end

    private

    def log(message, context = {})
      ForcedLogger.log(message, context.merge(store: store.try(:id), class: self.class.to_s))
    end

    def warn(message, context = {})
      ForcedLogger.warn(message, context.merge(store: store.try(:id), class: self.class.to_s))
    end

    def error(message, context = {})
      ForcedLogger.error(message, context.merge(store: store.try(:id), class: self.class.to_s))
    end
  end

end
