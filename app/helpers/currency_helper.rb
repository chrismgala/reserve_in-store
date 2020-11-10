module CurrencyHelper
  def usd_to_cad(usd)
    Bananastand::CurrencyConverter.convert(usd, from: 'USD', to: 'CAD')
  end

  def usd_to_cad_rate
    Bananastand::CurrencyConverter.currency_rate(from: 'USD', to: 'CAD')
  end

  def nice_currency(val, opts = {})
    currency(val, opts).to_s.gsub('$0.00', '$0')
  end

  def currency(val, opts = {})
    val ||= 0

    opts[:rounding_threshold] = 1000 if opts[:rounding_threshold].nil?
    opts[:use_current_store] = false if opts[:use_current_store].nil?
    opts[:use_k] = false if opts[:use_k].nil?
    opts[:k_threshold] = 10000 if opts[:k_threshold].nil?
    opts[:use_m] = opts[:use_k] if opts[:use_m].nil?
    opts[:m_threshold] = 10000000 if opts[:m_threshold].nil?

    return current_store.currency(val, opts) if opts[:use_current_store] && current_store

    suffix = ''
    displayed_val = val
    always_round = opts[:always_round].to_bool
    rounding_precision = 0

    if opts[:use_m] && val >= opts[:m_threshold]
      displayed_val = val / 1000000
      suffix = 'm'
      always_round ||= true
      rounding_precision = 1 if displayed_val < 100
    elsif opts[:use_k] && val >= opts[:k_threshold]
      displayed_val = val.to_f / 1000
      suffix = 'k'
      always_round ||= true
      rounding_precision = 1 if displayed_val < 100
    end

    currency_params = {}
    if always_round || displayed_val >= opts[:rounding_threshold]
      displayed_val = displayed_val.round(rounding_precision)
      currency_params[:precision] = rounding_precision
      currency_params[:unit] = opts[:unit] unless opts[:unit].nil?
    end

    str = ActionController::Base.helpers.number_to_currency(displayed_val, currency_params)

    # $10.0k => $10k
    str = str.sub(/^(.+)\.0$/, '\1') if opts[:use_k] || opts[:use_m]

    str + suffix

    str = str.chomp('.00').gsub(/(\.[0-9]{2})$/, '<sup>\1</sup>').html_safe if opts[:small_cents]

    str
  end

  ##
  # A nice display with currency conversion support for monthly prices
  # @param amount [Float] Amount to display
  # @param currency [String|Symbol] What currency should the price be in? Defaults to USD
  # @param round: [Boolean] If true the number will be rounded to the nearest whole number
  # @return [String] Amount per month
  def nice_monthly_amount(amount, currency = :usd, round: true, include_mo: true, use_k: false)
    converted_price = Bananastand::CurrencyConverter.convert(amount, to: currency).to_f
    converted_price = converted_price.round if round

    if converted_price > 10000 || use_k
      converted_price = (converted_price.to_f / 100).round.to_f / 10
      use_k = true
    end

    price_str = ActionController::Base.helpers.number_to_currency(converted_price).gsub('.00','')

    if use_k
      price_str = "#{price_str}k"
      price_str = price_str.gsub(/(.+\.[0-9])0k/i, '\1k').gsub(/(.+)\.0+k/, '\1k')
    end

    price_str = "#{price_str}/mo" if include_mo
    price_str
  end

  ##
  # Just a quick way to use #nice_monthly_amount for internal reporting mostly
  def nice_monthly_amount_with_cad(amount, opts = {})
    nice_two_currency_monthly_amt(amount, :usd, :cad, opts)
  end

  ##
  # Just a quick way to use #nice_monthly_amount for internal reporting mostly
  # Displays the USD to the right
  def nice_monthly_amount_with_usd(amount, opts = {})
    nice_two_currency_monthly_amt(amount, :cad, :usd, opts)
  end

  def nice_two_currency_monthly_amt(amount, main_currency = :usd, other_currency = :cad, opts = {})
    content = ""
    unless opts[:plain_text] || amount == 0
      tooltip_content = "#{nice_monthly_amount(amount, other_currency)} #{other_currency.to_s.upcase}"
      tooltip_content += " #{opts[:tooltip_addon]}" if opts[:tooltip_addon].present?
      content += "<span class=\"hover-stat\" data-toggle=\"tooltip\" title=\"#{tooltip_content}\" data-currency=\"#{main_currency.to_s.upcase}\">"
    end

    content += nice_monthly_amount(amount, main_currency)

    if amount > 0
      if opts[:plain_text]
        content += " (#{nice_monthly_amount(amount, other_currency)} #{other_currency.to_s.upcase})"
      else
        content += "</span>"
      end
    end

    content.html_safe
  end
end
