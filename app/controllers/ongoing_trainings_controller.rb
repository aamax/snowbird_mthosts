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
    @ongoing_training = OngoingTraining.new()
    @training_dates = TrainingDate.all.order(shift_date: :desc)
    @hosts = User.where(active_user: true).order(:name)
  end

  def create
    @user = User.find_by(id: params[:ongoing_training][:user_id])
    user_id = nil
    unless @user.nil?
      if @user.is_working?(training_date.shift_date)
        flash[:alert] = "Error creating training shift: Host is already working."
        redirect_to new_ongoing_training_path
        return
      end
    else
      user_id = @user.id
      if params[:ongoing_training][:is_trainer] == '1'
        if !@user.ongoing_trainer?
          flash[:alert] = "Error creating training shift: Host must be a Trainer to take this shift."
        end
        redirect_to new_ongoing_training_path
        return
      end
    end

    training_date = TrainingDate.find_by(id: params[:training_date])
    if training_date.nil?
      flash[:alert] = "Error creating training shift: Shift Date must be set."
      redirect_to new_ongoing_training_path
      return
    end

    training_params = { training_date_id: training_date.id,
                        user_id: user_id,
                        is_trainer: params[:ongoing_training][:is_trainer] == 1 }
    @training = OngoingTraining.create(training_params)

    redirect_to ongoing_trainings_path
  end


  def destroy
    training = OngoingTraining.find(params[:id])
    if !training.destroy
      flash[:alert] = "Error destroying training."
    else
      flash[:success] = "success deleting training"
    end
    redirect_to ongoing_trainings_path
  end

  def edit
    @ongoing_training = OngoingTraining.find(params[:id])
    @training_dates = TrainingDate.all.order(shift_date: :desc)
    @hosts = User.where(active_user: true).order(:name)
  end

  def update
    @ongoing_training = OngoingTraining.find_by(id: params[:id])
    @training_date = TrainingDate.find_by(id: params[:training_date])
    @user = User.find_by(id: params[:ongoing_training][:user_id])
    user_id = nil
    user_id = @user.id if @user
    if @training_date.nil?
      flash[:alert] = "Error updating Training: date not found."
      redirect_to ongoing_trainings_path
      return
    end
    if params[:ongoing_training][:is_trainer] == '1'
      if !@user.nil? && !@user.ongoing_trainer?
        flash[:alert] = "Error creating training shift: Host must be a Trainer to take this shift."
        redirect_to ongoing_trainings_path
        return
      end
    end
    @ongoing_training.training_date_id = @training_date.id
    @ongoing_training.user_id = user_id
    @ongoing_training.is_trainer = params[:ongoing_training][:is_trainer]
    @ongoing_training.save
    redirect_to ongoing_trainings_path
  end

  def drop_shift
    @ongoing_training = OngoingTraining.find(params[:id])
    @ongoing_training.user_id = nil
    @ongoing_training.save
    redirect_to ongoing_trainings_path
  end

  def select_ongoing_training
    @trainer_dates = OngoingTraining.where('is_trainer = true and user_id is null').map(&:training_date).uniq
    @trainee_dates = OngoingTraining.where('is_trainer = false and user_id is null').map(&:training_date).uniq
    @selected_trainings = current_user.ongoing_trainings
  end

  def make_ongoing_training_selection
    training_date = TrainingDate.find_by(id: params[:id])
    role = params[:is_trainer] == 'trainee' ? 'false' : 'true'
    shift = training_date.ongoing_trainings.where("user_id is null and is_trainer = #{role}").first
    if shift.nil?
      flash[:error] = 'ERROR - training shift no longer available.'
      redirect_to :back
    else
      shift.user_id = current_user.id
      shift.save
      flash[:success] = 'Training shift assigned successfully'
      redirect_to '/select_ongoing_training'
    end
  end

  private
  # def trainings_params
  #   params.require(:training).permit(:shift_date, :user_id, :is_trainer)
  # end
end
