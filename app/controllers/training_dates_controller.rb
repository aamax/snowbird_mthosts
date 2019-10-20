class TrainingDatesController < ApplicationController
  load_and_authorize_resource

  respond_to :html, :json, :js

  def index
    @training_dates = TrainingDate.all.order(:shift_date)
  end

  def new
    training_dates = TrainingDate.all.order(:shift_date).last
    @shift_date = training_dates.shift_date + 1.day unless training_dates.nil?
    @shift_date ||= Date.today
    @training_date = TrainingDate.new(shift_date: @shift_date)
  end

  def create
    training_date = TrainingDate.find_by(shift_date: params[:training_shift_date])
    if !training_date.nil?
      flash[:alert] = "Error creating training shift: Training Date already exists."
      redirect_to training_dates_path
      return
    end
    @ongoing_training = TrainingDate.create(shift_date: params[:training_shift_date])

    redirect_to ongoing_trainings_path
  end

  def destroy
    training_date = TrainingDate.find(params[:id])
    if training_date.ongoing_trainings.count > 0
      flash[:alert] = "Error destroying training date - referential integrity."
    else
      if !training_date.destroy
        flash[:alert] = "Error destroying training date."
      else
        flash[:success] = "success deleting shift"
      end
    end
    redirect_to ongoing_trainings_path
  end



end

