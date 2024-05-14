# frozen_string_literal: true

module Chouette
  class WorkbenchController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include WithinWorkgroup

    belongs_to :workbench

    def policy_context_class
      Policy::Context::Workbench
    end

    private

    def current_workgroup
      workbench&.workgroup
    end

    def workbench
      association_chain
      get_parent_ivar(:workbench)
    end
    alias current_workbench workbench
    alias owner_workbench workbench
  end
end
