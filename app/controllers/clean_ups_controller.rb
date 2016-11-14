class CleanUpsController < ChouetteController
  respond_to :html, :only => [:create]
  belongs_to :referential

  def create
    clean_up = CleanUp.new(clean_up_params)
    clean_up.referential = @referential
    if clean_up.valid?
      clean_up.save
    else
      flash[:alert] = clean_up.errors.full_messages.join("<br/>")
    end
    redirect_to referential_path(@referential)
  end

  def clean_up_params
    params.require(:clean_up).permit(:keep_lines, :keep_stops, :keep_companies, :keep_networks, :keep_group_of_lines, :expected_date)
  end
end
