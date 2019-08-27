module HasFlags
  extend ActiveSupport::Concern

  included do
    scope :that_have, -> (key) { where("flags ->> ? IS NOT NULL", key)}
    scope :that_have_not, -> (key) { where("flags ->> ? IS NULL", key)}
  end


  def has(key)
    self.flags = flags.to_h.with_indifferent_access.merge({ key => Time.now.to_i })
    self
  end

  def has_not(key)
    self.flags = flags.to_h.with_indifferent_access.except(key)
    self
  end

  def has?(key)
    flags.to_h.with_indifferent_access[key].present?
  end

  def has!(key)
    has(key).save!
  end

  def has_not!(key)
    has_not(key).save!
  end

  def method_missing(method_name, *arguments, &block)
    if method_name.to_s =~ /^has_not_([a-z0-9_]+)\?$/
      has_not?($1)
    elsif method_name.to_s =~ /^has_not_([a-z0-9_]+)!$/
      has_not!($1)
    elsif method_name.to_s =~ /^has_not_([a-z0-9_]+)$/
      has_not($1)
    elsif method_name.to_s =~ /^has_([a-z0-9_]+)\?$/
      has?($1)
    elsif method_name.to_s =~ /^has_([a-z0-9_]+)!$/
      has!($1)
    elsif method_name.to_s =~ /^has_([a-z0-9_]+)$/
      has($1)
    else
      super
    end
  end

  def respond_to?(method_name, include_private = false)
    (method_name.to_s =~ /^has_(not_)?([a-z0-9_]+)[?!]?$/) || super
  end

end
