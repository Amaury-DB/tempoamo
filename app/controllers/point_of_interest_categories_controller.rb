class PointOfInterestCategoriesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => PointOfInterest::Category

  before_action :decorate_point_of_interest_category, only: %i[show new edit]
  after_action :decorate_point_of_interest_category, only: %i[create update]

  before_action :point_of_interest_category_params, only: [:create, :update]

  belongs_to :workbench
  belongs_to :shape_referential, singleton: true

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @point_of_interest_categories = PointOfInterestCategoryDecorator.decorate(
          collection,
          context: {
            workbench: @workbench,
          }
        )
      end
    end
  end

  protected

  alias point_of_interest_category resource
  alias shape_referential parent

  def collection
    @point_of_interest_categories = parent.point_of_interest_categories.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_point_of_interest_category
    object = point_of_interest_category rescue build_resource
    @point_of_interest_category = PointOfInterestCategoryDecorator.decorate(
      object,
      context: {
        workbench: @workbench
      }
    )
  end

  def shape_provider
    workbench.shape_providers.first
  end

  def point_of_interest_category_params
    params.require(:point_of_interest_category).permit(
      :name,
      :created_at,
      :updated_at,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
