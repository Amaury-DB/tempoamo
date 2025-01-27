# frozen_string_literal: true

# Selects which models need to be included into an Export
module Export::Scope
  def self.build(referential, **options)
    Options.new(referential, options).scope
  end

  class Builder
    def initialize(referential)
      @scope = All.new(referential)
      yield self if block_given?
    end

    def internal_scopes
      @internal_scopes ||= []
    end

    def current_scope
      internal_scopes.last || @scope
    end

    def scheduled
      internal_scopes << Scheduled.new(current_scope)
      self
    end

    def lines(line_ids)
      internal_scopes << Lines.new(current_scope, line_ids)
      self
    end

    def period(date_range)
      internal_scopes << DateRange.new(current_scope, date_range)
      self
    end

    def stateful(export_id)
      internal_scopes << Stateful.new(current_scope, export_id)
      self
    end

    def scope
      @scope = current_scope

      internal_scopes.each do |scope|
        scope.final_scope = @scope if scope.respond_to? :final_scope=
      end

      @scope
    end
  end

  class Options
    attr_reader :referential
    attr_accessor :duration, :date_range, :line_ids, :line_provider_ids, :company_ids, :export_id, :stateful

    def initialize(referential, attributes = {})
      @referential = referential

      @stateful = true
      attributes.each { |k, v| send "#{k}=", v }
    end

    def line_ids
      @line_ids || companies_line_ids || line_provider_line_ids
    end

    def line_provider_line_ids
      referential.line_referential.lines.where(line_provider: line_provider_ids).pluck(:id) if line_provider_ids
    end

    def companies_line_ids
      referential.line_referential.lines.where(company: company_ids).pluck(:id) if company_ids
    end

    def builder
      @builder ||= Builder.new(referential) do |builder|
        builder.lines(line_ids) if line_ids
        builder.period(date_range) if date_range
        builder.scheduled
        if stateful
          builder.stateful(export_id)
        else
          Rails.logger.debug 'Disable stateful scope'
        end
      end
    end

    delegate :scope, to: :builder
  end

  class All
    attr_reader :referential

    def initialize(referential)
      @referential = referential
    end

    delegate :workgroup, :workbench, :line_referential, :stop_area_referential, :metadatas, to: :referential
    delegate :shape_referential, :fare_referential, to: :workgroup

    delegate :companies, :networks, :line_notices, to: :line_referential
    delegate :entrances, to: :stop_area_referential

    delegate :shapes, :point_of_interests, to: :shape_referential
    delegate :fare_zones, :fare_products, :fare_validities, to: :fare_referential

    delegate :codes, :contracts, to: :workgroup

    delegate :vehicle_journeys, :vehicle_journey_at_stops, :journey_patterns, :stop_points,
             :time_tables, :routes, :referential_codes, :routing_constraint_zones, to: :referential

    def organisations
      # Find organisations which provided metadata in the referential
      # Only works for merged/aggregated datasets
      organisation_ids = metadatas.joins(referential_source: :organisation).distinct.pluck('organisations.id')

      # Use the Referential owner in fallback
      if organisation_ids.empty?
        organisation_ids = [ referential.organisation_id ]
      end

      workgroup.organisations.where(id: organisation_ids)
    end

    def stop_areas
      (workbench || stop_area_referential).stop_areas
    end

    def lines
      (workbench || line_referential).lines
    end

    def validity_period
      @validity_period ||= Period.for_range(referential.validity_period)
    end
  end

  # By default a Scope uses the current_scope collection.
  class Base < SimpleDelegator
    def initialize(current_scope)
      super current_scope
      @current_scope = current_scope
    end

    def empty?
      vehicle_journeys.empty?
    end

    attr_reader :current_scope

    def vehicle_journeys
      @vehicle_journeys ||= current_scope.vehicle_journeys
    end

    def inspect
      "#<#{self.class}:#{object_id} @current_scope=#{current_scope.inspect}>"
    end
  end

  class Scheduled < Base
    attr_writer :final_scope

    def final_scope
      @final_scope || current_scope
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.scheduled(final_scope.time_tables)
    end

    def final_scope_vehicle_journeys
      final_scope.vehicle_journeys
    end

    def lines
      current_scope.lines.distinct.joins(routes: :vehicle_journeys)
                   .where('vehicle_journeys.id' => final_scope_vehicle_journeys)
    end

    def companies
      current_scope.companies.where(id: company_ids).or(
        current_scope.companies.where(id: secondary_company_ids)
      )
    end

    def company_ids
      lines.where.not(company_id: nil).select(:company_id).distinct
    end

    def secondary_company_ids
      lines.where.not(secondary_company_ids: nil).select('unnest(secondary_company_ids)').distinct
    end

    def networks
      current_scope.networks.where(id: lines.where.not(network_id: nil).select(:network_id))
    end

    def vehicle_journey_at_stops
      current_scope.vehicle_journey_at_stops.where(vehicle_journey: final_scope_vehicle_journeys)
    end

    def routes
      current_scope.routes.where(id: final_scope_vehicle_journeys.select(:route_id).distinct)
    end

    def journey_patterns
      current_scope.journey_patterns.where(id: final_scope_vehicle_journeys.select(:journey_pattern_id).distinct)
    end

    def shapes
      current_scope.shapes.where(id: journey_patterns.select(:shape_id).distinct)
    end

    def stop_points
      current_scope.stop_points.distinct.where(route_id: routes)
    end

    def stop_areas
      @stop_areas ||=
        begin
          stop_areas_ids =
            (stop_areas_in_routes.pluck(:id) + stop_areas_in_specific_vehicle_journey_at_stops.pluck(:id)).uniq
          current_scope.stop_areas.where(id: stop_areas_ids)
        end
    end

    def stop_areas_in_routes
      current_scope.stop_areas.joins(routes: :vehicle_journeys).distinct
                   .where('vehicle_journeys.id' => final_scope_vehicle_journeys)
    end

    def stop_areas_in_specific_vehicle_journey_at_stops
      current_scope.stop_areas.joins(:specific_vehicle_journey_at_stops).distinct
                   .where('vehicle_journey_at_stops.vehicle_journey_id' => final_scope_vehicle_journeys)
    end

    def entrances
      current_scope.entrances.where(stop_area: stop_areas)
    end

    def routing_constraint_zones
      current_scope.routing_constraint_zones.where(route: routes)
    end

    def fare_products
      current_scope.fare_products.where(company: companies).or(current_scope.fare_products.where(company: nil))
    end

    def fare_validities
      # TODO: we should filter Validities according zones & exported stop areas
      current_scope.fare_validities.by_products(fare_products)
    end

    def contracts
      current_scope.contracts.with_lines(lines)
    end

    def line_notices
      current_scope.line_notices.joins(:lines).where('lines.id' => lines).distinct
    end
  end

  # Selects VehicleJourneys in a Date range
  class DateRange < Base
    attr_reader :date_range

    def initialize(current_scope, date_range)
      super current_scope
      @date_range = date_range
    end

    def time_tables
      current_scope.time_tables.applied_at_least_once_in(date_range)
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_matching_timetable(date_range)
    end

    def metadatas
      current_scope.metadatas.include_daterange(date_range)
    end

    def validity_period
      current_scope.validity_period & date_range
    end
  end

  # Selects VehicleJourneys associated to selected lines
  class Lines < Base
    attr_reader :selected_line_ids

    def initialize(current_scope, selected_line_ids)
      super current_scope
      @selected_line_ids = selected_line_ids
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_lines(selected_line_ids)
    end

    def metadatas
      current_scope.metadatas.with_lines(selected_line_ids)
    end

    def contracts
      current_scope.contracts.with_lines(lines)
    end

    def line_notices
      current_scope.line_notices.joins(:lines).where('lines.id' => selected_line_ids).distinct
    end

    def time_tables
      current_scope.time_tables.where(id: time_table_ids)
    end

    private

    def time_table_ids
      current_scope.time_tables.joins(:lines).where('lines.id' => selected_line_ids).distinct.select(:id)
    end
  end

  class Stateful < Base
    attr_reader :export_id

    def initialize(current_scope, export_id = nil)
      super current_scope
      @export_id = export_id
    end

    def vehicle_journeys
      unless @loaded
        model_scope = current_scope.vehicle_journeys

        if model_scope.exists?
          columns = ['uuid', 'export_id', 'model_type', 'model_id'].reject{ |c| c == 'export_id' && export_id.nil? }.join(',')
          constants = ["'#{uuid}'", export_id, "'Chouette::VehicleJourney'"].compact
          models = model_scope.select(constants, :id)

          query = <<~SQL
            INSERT INTO public.exportables (#{columns}) #{models.to_sql}
          SQL
          ActiveRecord::Base.connection.execute query
        end

        @loaded = true
      end

      exportable_vehicle_journeys
    end

    def exportable_vehicle_journeys
      @exportable_vehicle_journeys ||=
        begin
          exportables = Exportable.where(uuid: uuid, model_type: 'Chouette::VehicleJourney', processed: false)
          Chouette::VehicleJourney.where(id: exportables.select(:model_id))
        end
    end

    private

    def uuid
      @uuid ||= SecureRandom.uuid
    end
  end
end
