# frozen_string_literal: true

# Generic model to manage address attributes
class Address
  attr_accessor :house_number, :street_name, :post_code, :city_name, :country_code

  def initialize(attributes = {})
    attributes.each { |k,v| send "#{k}=", v }
  end

  def house_number_and_street_name
    [house_number, street_name].delete_if(&:blank?).join(' ')
  end

  def country
    return unless country_code

    ISO3166::Country[country_code]
  end

  def country_name
    return unless country

    country.translations[I18n.locale.to_s] || country.name
  end

  alias postal_code post_code
end
