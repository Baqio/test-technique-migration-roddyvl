module Importer::Normalization
  module_function

  COUNTRY_CODES = {
    "france"    => "FR",
    "belgique"  => "BE",
    "allemagne" => "DE"
  }.freeze

  def text(value)
    return nil if value.nil?

    value.to_s.strip
  end

  def zip(value, _country_code = "FR")
    value.to_s.strip.rjust(5, "0")
  end

  def country_code(value)
    text = value.to_s.strip
    return text.upcase if text.length == 2

    COUNTRY_CODES[text.downcase]
  end

  def decimal(value)
    value.to_s.to_f
  end

  def date(value)
    return value if value.is_a?(Date)
    return nil if value.to_s.strip.empty?

    Date.strptime(value.to_s.strip, "%d/%m/%Y")
  end
end
