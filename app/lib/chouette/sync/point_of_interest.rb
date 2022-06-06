module Chouette::Sync
  module PointOfInterest
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :point_of_interest,
          resource_id_attribute: :id,
          model_type: :point_of_interest,
          resource_decorator: Decorator,
          model_id_attribute: :codes,
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        delegate :contact_details, to: :operating_organisation_view
        delegate :target, to: :updater

        def position
          "#{longitude} #{latitude}"
        end

        def address
          postal_address&.address_line_1
        end

        def zip_code
          postal_address&.post_code
        end

        def city_name
          postal_address&.town
        end

        def country
          postal_address&.country_name
        end

        def email
          contact_details&.email
        end

        def phone
          contact_details&.phone
        end

        def point_of_interest_category_name
          classifications.first&.name
        end

        def point_of_interest_category
          if point_of_interest_category_name.present?
            point_of_interest_categories.find_by(name: point_of_interest_category_name)
          end
        end

        def point_of_interest_category_id
          point_of_interest_category&.id
        end

        def point_of_interest_categories
          target.point_of_interest_categories
        end

        def codes_attributes
          return [] unless key_list.present?
          key_list.map do |netex_code|
            {
              short_name: netex_code.key,
              value: netex_code.value
            }
          end
        end

        def model_attributes
          {
            name: name,
            url: url,
            position_input: position,
            address: address,
            zip_code: zip_code,
            city_name: city_name,
            country: country,
            phone: phone,
            email: email,
            point_of_interest_category_id: point_of_interest_category_id,
            codes_attributes: codes_attributes
          }
        end
      end
    end
  end
end