module Bananastand
  ##
  # Allows you to convert numbers to different currencies using the latest rates from the internet
  class CurrencyConverter
    ##
    # Convert the amount provided from the currency code to the other currency code specified.
    # @param amount [Float] Amount to convert
    # @param from [String|Symbol] Currency code to convert from (ie USD)
    # @param to [String|Symbol] Currency code to convert to (ie CAD)
    # @return [Float] resulting amount in the new currency
    def self.convert(amount, from: :usd, to:, round: true)
      from = from.to_s.upcase
      to = to.to_s.upcase

      return amount if from == to # No conversion needed since converting to the same currency

      result = (currency_rate(from: from, to: to) * amount.to_f)
      round ? result.round(2) : result
    end

    ##
    # @return [Float] The currency rate to convert 1 USD to CAD
    def self.usd_to_cad_rate
      currency_rate(from: 'USD', to: 'CAD')
    end

    ##
    # Get the currency rate to convert from/to the codes specified.
    # Caches the result for 1 day.
    # @param from [String|Symbol] Currency code to convert from (ie USD)
    # @param to [String|Symbol] Currency code to convert to (ie CAD)
    # @return [Float] exchange rate
    def self.currency_rate(from:, to:)
      to = to.to_s.upcase
      from = from.to_s.upcase

      return 1 if from == to # Converting to the same currency

      # If we're offline then don't try to get currency rate from the web and used the local estimate instead
      if Rails.env.development? || ENV['OFFLINE_MODE'].to_bool
        est_rate = estimated_currency_rate(from: from, to: to)
        return est_rate if est_rate.present?
      end

      url = 'https://data.fixer.io/latest?' + {symbols: to, base: from, access_key: fixer_api_key }.to_param

      Rails.cache.fetch("bananastand/currency_converter/currency_rate/#{from}_to_#{to}", expires_in: 1.day) do
        HTTParty.get(url)['rates'][to].to_f
      end
    end

    ##
    # Uses the hash stored locally here to get currency rates.
    # @see #est_usd_currency_rates
    # @param from [String|Symbol] Currency code to convert from (ie USD)
    # @param to [String|Symbol] Currency code to convert to (ie CAD)
    # @return [Float|NilClass] Nil if we could not estimate it with local stored value (ie we don't have the tables stored)
    def self.estimated_currency_rate(from:, to:)
      if from == 'USD'
        est_usd_currency_rates[to.to_s.upcase]
      elsif to == 'USD'
        (1.0 / est_usd_currency_rates[from.to_s.upcase]).round(6)
      else
        nil
      end
    end

    private

    ##
    # Last updated June 5, 2018, 10:18AM from data.fixer.io
    # This is used in local development environments.
    # @return [Hash] with string keys
    def self.est_usd_currency_rates
      {
        'AED' => 3.672703,
        'AFN' => 71.199997,
        'ALL' => 106.519997,
        'AMD' => 482.519989,
        'ANG' => 1.780126,
        'AOA' => 237.055986,
        'ARS' => 24.968977,
        'AUD' => 1.3156,
        'AWG' => 1.78,
        'AZN' => 1.699501,
        'BAM' => 1.679597,
        'BBD' => 2,
        'BDT' => 84.290001,
        'BGN' => 1.666402,
        'BHD' => 0.377403,
        'BIF' => 1751,
        'BMD' => 1,
        'BND' => 1.322803,
        'BOB' => 6.850273,
        'BRL' => 3.785598,
        'BSD' => 1,
        'BTC' => 0.000136,
        'BTN' => 67.050003,
        'BWP' => 9.955197,
        'BYN' => 1.999554,
        'BYR' => 19600,
        'BZD' => 1.997797,
        'CAD' => 1.30593,
        'CDF' => 1565.497158,
        'CHF' => 0.98864,
        'CLF' => 0.02312,
        'CLP' => 634.359985,
        'CNY' => 6.4046,
        'COP' => 2873.5,
        'CRC' => 564.250057,
        'CUC' => 1,
        'CUP' => 26.5,
        'CVE' => 94.559998,
        'CZK' => 21.992701,
        'DJF' => 177.550003,
        'DKK' => 6.38125,
        'DOP' => 49.509998,
        'DZD' => 116.299004,
        'EGP' => 17.849696,
        'ERN' => 14.990266,
        'ETB' => 27.200001,
        'EUR' => 0.857304,
        'FJD' => 2.049869,
        'FKP' => 0.748103,
        'GBP' => 0.74942,
        'GEL' => 2.4458,
        'GGP' => 0.749528,
        'GHS' => 4.698498,
        'GIP' => 0.748397,
        'GMD' => 46.799999,
        'GNF' => 8953.000248,
        'GTQ' => 7.335951,
        'GYD' => 206.089996,
        'HKD' => 7.846498,
        'HNL' => 23.853001,
        'HRK' => 6.326976,
        'HTG' => 63.130001,
        'HUF' => 273.23999,
        'IDR' => 13872,
        'ILS' => 3.570301,
        'IMP' => 0.749528,
        'INR' => 67.161003,
        'IQD' => 1184,
        'IRR' => 42165.000418,
        'ISK' => 105.379997,
        'JEP' => 0.749528,
        'JMD' => 126.209999,
        'JOD' => 0.708495,
        'JPY' => 109.846001,
        'KES' => 100.900002,
        'KGS' => 68.377701,
        'KHR' => 4060.899902,
        'KMF' => 420.600006,
        'KPW' => 900.000204,
        'KRW' => 1070.189941,
        'KWD' => 0.302294,
        'KYD' => 0.819885,
        'KZT' => 331.76001,
        'LAK' => 8340.000131,
        'LBP' => 1504.999522,
        'LKR' => 158.199997,
        'LRD' => 138.270004,
        'LSL' => 12.55958,
        'LTL' => 3.048697,
        'LVL' => 0.62055,
        'LYD' => 1.361098,
        'MAD' => 9.496055,
        'MDL' => 16.788006,
        'MGA' => 3270.000157,
        'MKD' => 52.51994,
        'MMK' => 1344.000402,
        'MNT' => 2401.000072,
        'MOP' => 8.081199,
        'MRO' => 353.999855,
        'MUR' => 34.099998,
        'MVR' => 15.56975,
        'MWK' => 716.099976,
        'MXN' => 20.3971,
        'MYR' => 3.977023,
        'MZN' => 58.990002,
        'NAD' => 12.758979,
        'NGN' => 358.000115,
        'NIO' => 31.439199,
        'NOK' => 8.146102,
        'NPR' => 107.199997,
        'NZD' => 1.427298,
        'OMR' => 0.3848,
        'PAB' => 1,
        'PEN' => 3.273502,
        'PGK' => 3.260102,
        'PHP' => 52.389999,
        'PKR' => 115.510002,
        'PLN' => 3.674096,
        'PYG' => 5671.000172,
        'QAR' => 3.639797,
        'RON' => 3.985014,
        'RSD' => 100.744698,
        'RUB' => 62.407101,
        'RWF' => 848.200012,
        'SAR' => 3.749938,
        'SBD' => 7.871498,
        'SCR' => 13.430149,
        'SDG' => 17.955201,
        'SEK' => 8.78408,
        'SGD' => 1.33611,
        'SHP' => 0.748402,
        'SLL' => 7849.999807,
        'SOS' => 563.000083,
        'SRD' => 7.420205,
        'STD' => 21012,
        'SVC' => 8.749787,
        'SYP' => 514.97998,
        'SZL' => 12.758025,
        'THB' => 31.976999,
        'TJS' => 9.026602,
        'TMT' => 3.4,
        'TND' => 2.567699,
        'TOP' => 2.284296,
        'TRY' => 4.6116,
        'TTD' => 6.649501,
        'TWD' => 29.823999,
        'TZS' => 2274.000279,
        'UAH' => 26.144988,
        'UGX' => 3781.999667,
        'USD' => 1,
        'UYU' => 31.069701,
        'UZS' => 7939.069824,
        'VEF' => 79799.999729,
        'VND' => 22828,
        'VUV' => 106.419998,
        'WST' => 2.562897,
        'XAF' => 562.02002,
        'XAG' => 0.060935,
        'XAU' => 0.000774,
        'XCD' => 2.699549,
        'XDR' => 0.706048,
        'XOF' => 562.02002,
        'XPF' => 102.332973,
        'YER' => 249.699997,
        'ZAR' => 12.758501,
        'ZMK' => 9001.199204,
        'ZMW' => 10.030254,
        'ZWL' => 322.355011
      }
    end

    def self.fixer_api_key
      @fixer_api_key ||= ENV['FIXER_API_KEY']
    end

  end
end
