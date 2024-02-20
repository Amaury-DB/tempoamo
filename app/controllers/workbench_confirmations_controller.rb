# frozen_string_literal: true

class WorkbenchConfirmationsController < Chouette::ResourceController
  defaults resource_class: Workbench::Confirmation, singleton: true

  def create
    create! do |success, _|
      workbench = @workbench_confirmation.workbench
      flash[:notice] = t('.success', workbench: workbench.name, workgroup: workbench.workgroup.name)
      success.html { redirect_to workbench_path workbench }
    end
  end

  protected

  def authorize_resource_class
    authorize_policy(parent_policy, :workbench_confirm?, Workbench)
  end

  def workbench_confirmation_params
    params.require(:workbench_confirmation).permit(
      :invitation_code
    )
  end
end
