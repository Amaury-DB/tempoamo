# frozen_string_literal: true

class ServiceFacilitySetsController < Chouette::ReferentialController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: ServiceFacilitySet

  def index
    index! do |format|
      format.html do
        @service_facility_sets = ServiceFacilitySetDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
            referential: referential
          }
        )
      end
    end
  end

  protected

  alias service_facility_set resource

  def scope
    @scope ||= referential.service_facility_sets
  end

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench, referential: referential }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench, referential: referential })
    )
  end

  def collection
    @service_facility_sets = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def service_facility_set_params
    params.require(:service_facility_set).permit(
      :name,
      associated_services: [],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end