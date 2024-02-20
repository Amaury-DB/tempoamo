# frozen_string_literal: true

module Chouette
  class ReferentialController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ReferentialSupport

    belongs_to :referential

    # switch referential before finding resource
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :authorize_resource, except: %i[new create index show]
    before_action :authorize_resource_class, only: %i[new create]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    include WithinWorkgroup

    def policy_context_class
      Policy::Context::Referential
    end

    private

    def current_workgroup
      current_workbench&.workgroup
    end

    def current_workbench
      referential&.workgroup&.workbenches&.find_by(organisation: current_organisation)
    end
  end
end
