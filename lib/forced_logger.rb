class ForcedLogger

  def self.log(msg, context = {})
    puts log_string(msg, context)
  end

  def self.warn(msg, context = {})
    if Rails.env.development?
      puts("WARNING: #{log_string(msg, context)}")
    else
      Rails.logger.warn(log_string(msg, context))
    end
  end

  def self.warning(msg, context = {})
    warn(msg, context)
  end

  ##
  # @param msg [Exception|String]
  # @param context [Hash] (optional) Options and context to use
  # @param context[:sentry] [Boolean] If set to true issue will be sent to sentry as well
  # @param context[:log] [String] If set, message will be sent to the log but not sent to sentry.
  def self.error(msg, context = {})
    if msg.is_a?(Exception)
      pd("ForcedLogger.error Exception: #{msg}\n", '=', :top, 1)
      pd(msg.backtrace[0..9].join("\n"), '=', :bottom, 1)

      context[:sentry] = true if context[:sentry].nil?
      Raven.capture_exception(msg, { extra: context.except(:sentry, :trace, :log) }) if context[:sentry]
      msg = msg.to_s
    else
      pd("ForcedLogger.error #{msg}", '=', 2)
      Raven.capture_message(msg, { extra: context.except(:sentry, :trace, :log) }) if context[:sentry]
    end
    Rails.logger.error(log_string(msg, context))
  end

  def self.log_string(msg, context = {})
    backtrace_content = (context[:trace] ? "   >>>#{Rails.backtrace_cleaner.clean(Thread.current.backtrace).join('>>>')}" : "")
    log_content = context[:log].present? ? " #{context[:log]}" : ''
    context = context.except(:sentry, :trace, :log)
    (context.map{ |k, v| "[#{k}=#{v}]"}.join('').to_s + " " + msg.to_s) + log_content + backtrace_content
  end

end
