class TrainingDatesController < ApplicationController
  # authorize_resource
  # load_resource

  respond_to :html, :json, :js

  def index
    @training_dates = TrainingDate.all
  end

  def new
    training_dates = TrainingDate.all.order(:shift_date).last
    @shift_date = training_dates.shift_date + 1.day unless training_dates.nil?
    @shift_date ||= Date.today
    @training_date = TrainingDate.new(shift_date: @shift_date)
  end

  def create
    training_date = TrainingDate.find_by(shift_date: params[:shift_date])
    if !training_date.nil?
      flash[:alert] = "Error creating training shift: Training Date already exists."
      redirect_to training_dates_path
      return
    end
    @ongoing_training = TrainingDate.create(shift_date: params[:training_shift_date])

    redirect_to trainings_path
  end
end

