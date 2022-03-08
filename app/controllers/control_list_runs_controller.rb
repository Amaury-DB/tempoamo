class ControlListRunsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Control::List::Run

  before_action :decorate_control_list_run, only: %i[show new edit]
  before_action :select_referentials, only: %i{new create}

	belongs_to :workbench
	belongs_to :control_list, optional: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(:page => 1) if collection.out_of_bounds?

        @control_list_runs = ControlListRunDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def create
    create! do |success, failure|
      failure.html do
        @control_list_run = ControlListRunDecorator.decorate(@control_list_run, context: { workbench: workbench })

        render 'new'
      end

			success.html do
        @control_list_run.enqueue
        redirect_to workbench_control_list_run_url(workbench, @control_list_run)
      end
    end
  end

  protected

  alias control_list parent
  alias control_list_run resource

  def collection
    workbench.control_list_runs.paginate(page: params[:page], per_page: 30)
  end

  def build_resource
    super.tap do |control_list_run|
      control_list_run.build_with_original_control_list
    end
  end

  private

  def decorate_control_list_run
    object = control_list_run rescue build_resource
    @control_list_run = ControlListRunDecorator.decorate(
      object,
      context: {
        workbench: workbench,
				control_list: control_list
      }
    )
  end

	def workbench
		@workbench ||= Workbench.find(params[:workbench_id])
	end

  def select_referentials
    @referentials ||= workbench.referentials.editable
  end

	def control_list_run_params
		params
      .require(:control_list_run)
      .permit(:name, :original_control_list_id, :referential_id)
      .with_defaults(creator: current_user.name)
      .delete_if { |_,v| v.blank? }
	end
end