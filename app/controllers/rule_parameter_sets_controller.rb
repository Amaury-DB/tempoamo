class RuleParameterSetsController < InheritedResources::Base
  defaults :resource_class => RuleParameterSet
  respond_to :html
  respond_to :js, :only => [ :mode ]

  def new
    @rule_parameter_set = RuleParameterSet.default( current_organisation)
    new!
  end

  def destroy
    if current_organisation.rule_parameter_sets.count == 1
      flash[:alert] = t('rule_parameter_sets.destroy.last_rps_protected')
      redirect_to organisation_rule_parameter_sets_path
    else
      destroy! do |success, failure|
        success.html { redirect_to organisation_rule_parameter_sets_path }
      end
    end
  end

  def update
    update!(rule_parameter_set_params) do |success, failure|
      success.html { redirect_to organisation_rule_parameter_sets_path }
    end
  end

  def create
    create!(rule_parameter_set_params) do |success, failure|
      success.html { redirect_to organisation_rule_parameter_sets_path }
    end
  end

  protected

  alias_method :rule_parameter_set, :resource

  def collection
    @rule_parameter_sets = current_organisation.rule_parameter_sets
  end

  def create_resource(rule_parameter_sets)
    rule_parameter_sets.organisation = current_organisation
    super
  end

  private

  def rule_parameter_set_params
    params.require(:rule_parameter_set).permit(:organisation, :name, :inter_stop_area_distance_min, :parent_stop_area_distance_max, :stop_areas_area, :inter_access_point_distance_min, :inter_connection_link_distance_max, :walk_default_speed_max, :walk_occasional_traveller_speed_max, :walk_frequent_traveller_speed_max, :walk_mobility_restricted_traveller_speed_max, :inter_access_link_distance_max, :inter_stop_duration_max, :facility_stop_area_distance_max, :check_lines_in_groups, :check_line_routes, :check_stop_parent, :check_connection_link_on_physical, :check_allowed_transport_modes, :allowed_transport_mode_coach, :inter_stop_area_distance_min_mode_coach, :inter_stop_area_distance_max_mode_coach, :speed_max_mode_coach, :speed_min_mode_coach, :inter_stop_duration_variation_max_mode_coach, :allowed_transport_mode_air, :inter_stop_area_distance_min_mode_air, :inter_stop_area_distance_max_mode_air, :speed_max_mode_air, :speed_min_mode_air, :inter_stop_duration_variation_max_mode_air, :allowed_transport_mode_waterborne, :inter_stop_area_distance_min_mode_waterborne, :inter_stop_area_distance_max_mode_waterborne, :speed_max_mode_waterborne, :speed_min_mode_waterborne, :inter_stop_duration_variation_max_mode_waterborne, :allowed_transport_mode_bus, :inter_stop_area_distance_min_mode_bus, :inter_stop_area_distance_max_mode_bus, :speed_max_mode_bus, :speed_min_mode_bus, :inter_stop_duration_variation_max_mode_bus, :allowed_transport_mode_ferry, :inter_stop_area_distance_min_mode_ferry, :inter_stop_area_distance_max_mode_ferry, :speed_max_mode_ferry, :speed_min_mode_ferry, :inter_stop_duration_variation_max_mode_ferry, :allowed_transport_mode_walk, :inter_stop_area_distance_min_mode_walk, :inter_stop_area_distance_max_mode_walk, :speed_max_mode_walk, :speed_min_mode_walk, :inter_stop_duration_variation_max_mode_walk, :allowed_transport_mode_metro, :inter_stop_area_distance_min_mode_metro, :inter_stop_area_distance_max_mode_metro, :speed_max_mode_metro, :speed_min_mode_metro, :inter_stop_duration_variation_max_mode_metro, :allowed_transport_mode_shuttle, :inter_stop_area_distance_min_mode_shuttle, :inter_stop_area_distance_max_mode_shuttle, :speed_max_mode_shuttle, :speed_min_mode_shuttle, :inter_stop_duration_variation_max_mode_shuttle, :allowed_transport_mode_rapid_transit, :inter_stop_area_distance_min_mode_rapid_transit, :inter_stop_area_distance_max_mode_rapid_transit, :speed_max_mode_rapid_transit, :speed_min_mode_rapid_transit, :inter_stop_duration_variation_max_mode_rapid_transit, :allowed_transport_mode_taxi, :inter_stop_area_distance_min_mode_taxi, :inter_stop_area_distance_max_mode_taxi, :speed_max_mode_taxi, :speed_min_mode_taxi, :inter_stop_duration_variation_max_mode_taxi, :allowed_transport_mode_local_train, :inter_stop_area_distance_min_mode_local_train, :inter_stop_area_distance_max_mode_local_train, :speed_max_mode_local_train, :speed_min_mode_local_train, :inter_stop_duration_variation_max_mode_local_train, :allowed_transport_mode_train, :inter_stop_area_distance_min_mode_train, :inter_stop_area_distance_max_mode_train, :speed_max_mode_train, :speed_min_mode_train, :inter_stop_duration_variation_max_mode_train, :allowed_transport_mode_long_distance_train, :inter_stop_area_distance_min_mode_long_distance_train, :inter_stop_area_distance_max_mode_long_distance_train, :speed_max_mode_long_distance_train, :speed_min_mode_long_distance_train, :inter_stop_duration_variation_max_mode_long_distance_train, :allowed_transport_mode_tramway, :inter_stop_area_distance_min_mode_tramway, :inter_stop_area_distance_max_mode_tramway, :speed_max_mode_tramway, :speed_min_mode_tramway, :inter_stop_duration_variation_max_mode_tramway, :allowed_transport_mode_trolleybus, :inter_stop_area_distance_min_mode_trolleybus, :inter_stop_area_distance_max_mode_trolleybus, :speed_max_mode_trolleybus, :speed_min_mode_trolleybus, :inter_stop_duration_variation_max_mode_trolleybus, :allowed_transport_mode_private_vehicle, :inter_stop_area_distance_min_mode_private_vehicle, :inter_stop_area_distance_max_mode_private_vehicle, :speed_max_mode_private_vehicle, :speed_min_mode_private_vehicle, :inter_stop_duration_variation_max_mode_private_vehicle, :allowed_transport_mode_bicycle, :inter_stop_area_distance_min_mode_bicycle, :inter_stop_area_distance_max_mode_bicycle, :speed_max_mode_bicycle, :speed_min_mode_bicycle, :inter_stop_duration_variation_max_mode_bicycle, :allowed_transport_mode_other, :inter_stop_area_distance_min_mode_other, :inter_stop_area_distance_max_mode_other, :speed_max_mode_other, :speed_min_mode_other, :inter_stop_duration_variation_max_mode_other, :check_network, :unique_column_objectid_object_network, :pattern_column_objectid_object_network, :min_size_column_objectid_object_network, :max_size_column_objectid_object_network, :unique_column_name_object_network, :pattern_column_name_object_network, :min_size_column_name_object_network, :max_size_column_name_object_network, :unique_column_registration_number_object_network, :pattern_column_registration_number_object_network, :min_size_column_registration_number_object_network, :max_size_column_registration_number_object_network, :check_company, :unique_column_objectid_object_company, :pattern_column_objectid_object_company, :min_size_column_objectid_object_company, :max_size_column_objectid_object_company, :unique_column_name_object_company, :pattern_column_name_object_company, :min_size_column_name_object_company, :max_size_column_name_object_company, :unique_column_registration_number_object_company, :pattern_column_registration_number_object_company, :min_size_column_registration_number_object_company, :max_size_column_registration_number_object_company, :check_group_of_line, :unique_column_objectid_object_group_of_line, :pattern_column_objectid_object_group_of_line, :min_size_column_objectid_object_group_of_line, :max_size_column_objectid_object_group_of_line, :unique_column_name_object_group_of_line, :pattern_column_name_object_group_of_line, :min_size_column_name_object_group_of_line, :max_size_column_name_object_group_of_line, :unique_column_registration_number_object_group_of_line, :pattern_column_registration_number_object_group_of_line, :min_size_column_registration_number_object_group_of_line, :max_size_column_registration_number_object_group_of_line, :check_stop_area, :unique_column_objectid_object_stop_area, :pattern_column_objectid_object_stop_area, :min_size_column_objectid_object_stop_area, :max_size_column_objectid_object_stop_area, :unique_column_name_object_stop_area, :pattern_column_name_object_stop_area, :min_size_column_name_object_stop_area, :max_size_column_name_object_stop_area, :unique_column_registration_number_object_stop_area, :pattern_column_registration_number_object_stop_area, :min_size_column_registration_number_object_stop_area, :max_size_column_registration_number_object_stop_area, :unique_column_city_name_object_stop_area, :pattern_column_city_name_object_stop_area, :min_size_column_city_name_object_stop_area, :max_size_column_city_name_object_stop_area, :unique_column_country_code_object_stop_area, :pattern_column_country_code_object_stop_area, :min_size_column_country_code_object_stop_area, :max_size_column_country_code_object_stop_area, :unique_column_zip_code_object_stop_area, :pattern_column_zip_code_object_stop_area, :min_size_column_zip_code_object_stop_area, :max_size_column_zip_code_object_stop_area, :check_access_point, :unique_column_objectid_object_access_point, :pattern_column_objectid_object_access_point, :min_size_column_objectid_object_access_point, :max_size_column_objectid_object_access_point, :unique_column_name_object_access_point, :pattern_column_name_object_access_point, :min_size_column_name_object_access_point, :max_size_column_name_object_access_point, :unique_column_city_name_object_access_point, :pattern_column_city_name_object_access_point, :min_size_column_city_name_object_access_point, :max_size_column_city_name_object_access_point, :unique_column_country_code_object_access_point, :pattern_column_country_code_object_access_point, :min_size_column_country_code_object_access_point, :max_size_column_country_code_object_access_point, :unique_column_zip_code_object_access_point, :pattern_column_zip_code_object_access_point, :min_size_column_zip_code_object_access_point, :max_size_column_zip_code_object_access_point, :check_access_link, :unique_column_objectid_object_access_link, :pattern_column_objectid_object_access_link, :min_size_column_objectid_object_access_link, :max_size_column_objectid_object_access_link, :unique_column_name_object_access_link, :pattern_column_name_object_access_link, :min_size_column_name_object_access_link, :max_size_column_name_object_access_link, :unique_column_link_distance_object_access_link, :min_size_column_link_distance_object_access_link, :max_size_column_link_distance_object_access_link, :unique_column_default_duration_object_access_link, :min_size_column_default_duration_object_access_link, :max_size_column_default_duration_object_access_link, :check_connection_link, :unique_column_objectid_object_connection_link, :pattern_column_objectid_object_connection_link, :min_size_column_objectid_object_connection_link, :max_size_column_objectid_object_connection_link, :unique_column_name_object_connection_link, :pattern_column_name_object_connection_link, :min_size_column_name_object_connection_link, :max_size_column_name_object_connection_link, :unique_column_link_distance_object_connection_link, :min_size_column_link_distance_object_connection_link, :max_size_column_link_distance_object_connection_link, :unique_column_default_duration_object_connection_link, :min_size_column_default_duration_object_connection_link, :max_size_column_default_duration_object_connection_link, :check_time_table, :unique_column_objectid_object_time_table, :pattern_column_objectid_object_time_table, :min_size_column_objectid_object_time_table, :max_size_column_objectid_object_time_table, :unique_column_comment_object_time_table, :pattern_column_comment_object_time_table, :min_size_column_comment_object_time_table, :max_size_column_comment_object_time_table, :unique_column_version_object_time_table, :pattern_column_version_object_time_table, :min_size_column_version_object_time_table, :max_size_column_version_object_time_table, :check_line, :unique_column_objectid_object_line, :pattern_column_objectid_object_line, :min_size_column_objectid_object_line, :max_size_column_objectid_object_line, :unique_column_name_object_line, :pattern_column_name_object_line, :min_size_column_name_object_line, :max_size_column_name_object_line, :unique_column_registration_number_object_line, :pattern_column_registration_number_object_line, :min_size_column_registration_number_object_line, :max_size_column_registration_number_object_line, :unique_column_number_object_line, :pattern_column_number_object_line, :min_size_column_number_object_line, :max_size_column_number_object_line, :unique_column_published_name_object_line, :pattern_column_published_name_object_line, :min_size_column_published_name_object_line, :max_size_column_published_name_object_line, :check_route, :unique_column_objectid_object_route, :pattern_column_objectid_object_route, :min_size_column_objectid_object_route, :max_size_column_objectid_object_route, :unique_column_name_object_route, :pattern_column_name_object_route, :min_size_column_name_object_route, :max_size_column_name_object_route, :unique_column_number_object_route, :pattern_column_number_object_route, :min_size_column_number_object_route, :max_size_column_number_object_route, :unique_column_published_name_object_route, :pattern_column_published_name_object_route, :min_size_column_published_name_object_route, :max_size_column_published_name_object_route, :check_journey_pattern, :unique_column_objectid_object_journey_pattern, :pattern_column_objectid_object_journey_pattern, :min_size_column_objectid_object_journey_pattern, :max_size_column_objectid_object_journey_pattern, :unique_column_name_object_journey_pattern, :pattern_column_name_object_journey_pattern, :min_size_column_name_object_journey_pattern, :max_size_column_name_object_journey_pattern, :unique_column_registration_number_object_journey_pattern, :pattern_column_registration_number_object_journey_pattern, :min_size_column_registration_number_object_journey_pattern, :max_size_column_registration_number_object_journey_pattern, :unique_column_published_name_object_journey_pattern, :pattern_column_published_name_object_journey_pattern, :min_size_column_published_name_object_journey_pattern, :max_size_column_published_name_object_journey_pattern, :check_vehicle_journey, :unique_column_objectid_object_vehicle_journey, :pattern_column_objectid_object_vehicle_journey, :min_size_column_objectid_object_vehicle_journey, :max_size_column_objectid_object_vehicle_journey, :unique_column_published_journey_name_object_vehicle_journey, :pattern_column_published_journey_name_object_vehicle_journey, :min_size_column_published_journey_name_object_vehicle_journey, :max_size_column_published_journey_name_object_vehicle_journey, :unique_column_published_journey_identifier_object_vehicle_journey, :pattern_column_published_journey_identifier_object_vehicle_journey, :min_size_column_published_journey_identifier_object_vehicle_journey, :max_size_column_published_journey_identifier_object_vehicle_journey, :unique_column_number_object_vehicle_journey, :min_size_column_number_object_vehicle_journey, :max_size_column_number_object_vehicle_journey)
  end
end

