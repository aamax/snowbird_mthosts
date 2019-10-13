# == Schema Information
#
# Table name: trainings
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  training_date_id :integer
#  is_trainer       :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class OngoingTrainingsController < ApplicationController
  # authorize_resource
  # load_resource

  respond_to :html, :json, :js

  def index
    @ongoing_trainings = OngoingTraining.all
    @training_dates = TrainingDate.all
  end

  def new
    @training = OngoingTraining.new()
    @training_dates = TrainingDate.all.order(shift_date: :desc)
    @hosts = User.where(active_user: true).order(:name)
  end

  def create
    @user = User.find_by(id: params[:training][:user_id])
    if @user.nil?
      flash[:alert] = "Error creating training shift: Host not set."
      redirect_to new_training_path
      return
    end
    if params[:training][:is_trainer] == '1'
      if !@user.ongoing_trainer?
        flash[:alert] = "Error creating training shift: Host must be a Trainer to take this shift."
      end
      redirect_to new_training_path
      return
    end

    training_date = TrainingDate.find_by(id: params[:training_date])
    if training_date.nil?
      flash[:alert] = "Error creating training shift: Shift Date must be set."
      redirect_to new_training_path
      return
    end

    # TODO: if user is already working that day - invalid...
    if @user.is_working?(training_date.shift_date)
      flash[:alert] = "Error creating training shift: Host is already working."
      redirect_to new_training_path
      return
    end

    training_params = { training_date_id: training_date.id,
                        user_id: @user.id,
                        is_trainer: params[:training][:is_trainer] == 1 }
    @training = Training.create(training_params)

    redirect_to trainings_path
  end


  def destroy
    redirect_to trainings_path
  end

  def update
    redirect_to trainings_path
  end

  private
  # def trainings_params
  #   params.require(:training).permit(:shift_date, :user_id, :is_trainer)
  # end
end
