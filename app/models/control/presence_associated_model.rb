module Control
    class PresenceAssociatedModel < Control::Base
      module Options
        extend ActiveSupport::Concern

        included do
          option :target_model
          option :collection
          option :minimum
          option :maximum

          enumerize :target_model, in: %w[Line StopArea Route JourneyPattern VehicleJourney TimeTable]
          validates :target_model, :collection, presence: true
          validates :minimum, :maximum, numericality: { only_integer: true, allow_nil: true }
        end

        def candidate_collections # rubocop:disable Metrics/MethodLength
          Chouette::ModelAttribute.empty do
            define Chouette::StopArea, :routes
            define Chouette::StopArea, :lines
            # define Chouette::StopArea, :entrances
            # define Chouette::StopArea, :connection_links
  
            define Chouette::Line, :routes
            # define Chouette::Line, :secondary_companies
  
            define Chouette::Route, :stop_points
            define Chouette::Route, :journey_patterns
            define Chouette::Route, :vehicle_journeys
  
            define Chouette::JourneyPattern, :stop_points
            define Chouette::JourneyPattern, :vehicle_journeys
  
            define Chouette::VehicleJourney, :time_tables
  
            define Chouette::TimeTable, :periods
            define Chouette::TimeTable, :dates
          end
        end

        def collection_attribute
          candidate_collections.find_by(model_name: target_model, name: collection)
        end
      end
      include Options

      validate :minimum_or_maximum

      

      private

      def minimum_or_maximum
        return if minimum.present? || maximum.present?

        errors.add(:minimum, :invalid)
      end

      class Run < Control::Base::Run
        include Options

        def run
          Rails.logger.debug faulty_counts.inspect

          faulty_models.find_each do |model|
            count = faulty_counts[model.id]
            human_name = model.try(:name) || model.try(:get_object)&.short_id

            control_messages.create(message_attributes: { name: human_name, count: count },
                                    criticity: criticity,
                                    source: model,
                                    message_key: :presence_associated_model)
          end
        end

        def context_collection
          case [target_model, collection]
          when %w[JourneyPattern stop_points]
            'journey_pattern_stop_points'
          when %w[TimeTable periods]
            'time_table_periods'
          when %w[TimeTable dates]
            'time_table_dates'
          else
            collection
          end
        end

        # Retrieve models where a faulty count is dedicated
        def faulty_models
          models.where(id: faulty_counts.keys)
        end

        # Retrieve model identifier (only) associated to a faulty county
        # Ex: { <route id 1> => <stop point count>, <route id 2> => <stop point count> }
        def faulty_counts
          @faulty_counts ||=
            begin
              associatied_models = context.send(context_collection)

              grouped_by_target_model =
                case [target_model, collection]
                when %w[VehicleJourney time_tables]
                  # Vehicle Journeys have many and belongs to Time Tables
                  associatied_models.joins(:vehicle_journeys).group(:vehicle_journey_id)
                when %w[StopArea routes]
                  # Stop Areas have many and belongs to Routes
                  associatied_models.joins(:stop_areas).group(:stop_area_id)
                when %w[StopArea lines]
                  associatied_models.joins(routes: :stop_areas).group(:stop_area_id)
                else
                  associatied_models.group("#{target_model.underscore}_id")
                end

              grouped_by_target_model.having(condition, { minimum: minimum, maximum: maximum }).count
            end
        end

        def model_collection
          @model_collection ||= target_model.underscore.pluralize.to_sym
        end
  
        def models
          @models ||= context.send(model_collection)
        end

        def condition
          if minimum.present? && maximum.present?
            'count(*) < :minimum or count(*) > :maximum'
          elsif minimum.present?
            'count(*) < :minimum'
          else
            'count(*) > :maximum'
          end
        end
      end
    end
  end
  