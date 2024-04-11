# frozen_string_literal: true

module Export
  # Manage all unique codes for a given Export::Scope
  class CodeProvider
    def initialize(export_scope)
      @export_scope = export_scope
    end

    attr_reader :export_scope

    COLLECTIONS = %w[
      stop_areas point_of_interests vehicle_journeys lines companies entrances contracts
      vehicle_journey_at_stops journey_patterns routes codes time_tables fare_validities 
      routing_constraint_zones networks fare_zones fare_products stop_points shapes
    ].freeze

    # Returns unique code for the given model (StopArea, etc)
    def code(model)
      return unless model&.id

      if collection = send(collection_name(model))
        collection.code(model.id)
      end
    end

    def codes(models)
      models.map { |model| code(model) }.compact
    end

    COLLECTIONS.each do |collection|
      define_method collection do
        if index = instance_variable_get("@#{collection}")
          return index
        end

        instance_variable_set("@#{collection}", Model.new(export_scope.send(collection)).index)
      end
    end

    def collection_name(model)
      begin
        model.model_name.collection
      rescue
        # When the model class is Chouette::StopPoint::Light::StopPoint...
        model.class.name.demodulize.underscore.pluralize
      end
    end

    class Model
      def initialize(collection)
        @collection = collection

        @codes = {}
      end

      attr_reader :collection

      def model_class
        @model_class ||= collection.model
      end

      ATTRIBUTES = %w[objectid uuid].freeze
      def attribute
        (ATTRIBUTES & model_class.column_names).first
      end

      def index
        @codes = collection.pluck(:id, attribute).to_h

        self
      end

      def register(model_id, as:)
        @codes[model_id] = as if as
      end

      def code(model_id)
        @codes[model_id] if model_id
      end

      def codes(model_ids)
        model_ids.map { |model_id| code(model_id) }.compact
      end

      def alias(model_id, as:)
        register model_id, as: code(as)
      end
    end

    # Default implementation when a real Export::CodeProvider isn't provided
    #
    # Export::CodeProvider.null.code(..) => nil
    # Export::CodeProvider.null.stop_areas.code(..) => nil
    def self.null
      @null ||= Null.new
    end

    class Null
      def code(_model_or_id); end

      def codes(_models_or_ids)
        []
      end

      def method_missing(name, *arguments)
        return self if name.end_with?('s') && arguments.empty?

        super
      end
    end
  end
end
