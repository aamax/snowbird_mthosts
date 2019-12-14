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
  load_and_authorize_resource

  respond_to :html, :json, :js

  def index
    @ongoing_trainings = OngoingTraining.includes(:training_date).includes(:user).to_a.sort { |a,b| a.shift_date <=> b.shift_date }
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
    training_date = TrainingDate.find_by(id: params['training_date'])
    if training_date.nil?
      flash[:alert] = "Error creating training shift: can't find training date id: #{params['training_date']}."
      redirect_to new_ongoing_training_path
      return
    end
    unless @user.nil?
      if @user.is_working?(training_date.shift_date)
        flash[:alert] = "Error creating training shift: Host is already working."
        redirect_to new_ongoing_training_path
        return
      end
      if params[:ongoing_training][:is_trainer] == '1'
        if !@user.ongoing_trainer?
          flash[:alert] = "Error creating training shift: Host must be a Trainer to take this shift."
        end
        redirect_to new_ongoing_training_path
        return
      end
      user_id = @user.id
    end

    training_date = TrainingDate.find_by(id: params[:training_date])
    if training_date.nil?
      flash[:alert] = "Error creating training shift: Shift Date must be set."
      redirect_to new_ongoing_training_path
      return
    end
    training_params = { training_date_id: training_date.id,
                        user_id: user_id,
                        is_trainer: params[:ongoing_training][:is_trainer] == '1' }

    @training = OngoingTraining.create(training_params)
    log_shift_selected(@training, @user)
    flash[:success] = "Training shift created."
    redirect_to ongoing_trainings_path
  end


  def destroy
    training = OngoingTraining.find(params[:id])
    if !training.destroy
      flash[:alert] = "Error destroying training."
    else
      flash[:success] = "success deleting training"
      delete_training_shift(training)
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
    flash[:success] = "Training shift updated."
    update_training_shift(@ongoing_training, @user)
    redirect_to ongoing_trainings_path
  end

  def drop_shift
    @ongoing_training = OngoingTraining.find(params[:id])
     training_user = @ongoing_training.user
    @ongoing_training.user_id = nil
    @ongoing_training.save
    flash[:success] = "Training shift dropped."
    log_shift_dropped(@ongoing_training, training_user, current_user) if !training_user.nil?

    redirect_to :back
  end

  def select_ongoing_training
    @trainer_dates = OngoingTraining.includes(:training_date).where('is_trainer = true and user_id is null').map(&:training_date).uniq
    @trainee_dates = OngoingTraining.includes(:training_date).where('is_trainer = false and user_id is null').map(&:training_date).uniq
    @selected_trainings = current_user.ongoing_trainings.includes(:training_date)
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
      log_shift_selected(shift, current_user)
      redirect_to '/select_ongoing_training'
    end
  end

  private

  def ongoing_training_params
    params.require(:ongoing_training).permit(:training_date_id, :user_id, :is_trainer)
  end

  def log_shift_dropped(shift, training_user, user_dropping)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    trainer_string = shift.is_trainer ? "Trainer" : "Trainee"
    ShiftLog.create(change_date: DateTime.now, user_id: user_dropping.id,
                    shift_id: shift.id, action_taken: "Dropped OGOMt Training Shift",
                    note: "#{user_dropping.name} DROPPED OGOMt Training shift #{shift_str} for user: #{training_user.name} dropped by: #{user_dropping.name} (#{trainer_string})")

  end

  def log_shift_selected(shift, training_user)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    trainer_string = shift.is_trainer ? "Trainer" : "Trainee"
    trainer_name = training_user.nil? ? "UNSET" : training_user.name
    ShiftLog.create(change_date: DateTime.now, user_id: current_user.id,
                    shift_id: shift.id, action_taken: "Selected OGOMt Training Shift",
                    note: "#{current_user.name} Selected OGOMt Training shift #{shift_str} for user: #{trainer_name} selected by: #{current_user.name} (#{trainer_string})")
  end

  def update_training_shift(shift, training_user)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    trainer_string = shift.is_trainer ? "Trainer" : "Trainee"
    ShiftLog.create(change_date: DateTime.now, user_id: current_user.id,
                    shift_id: shift.id, action_taken: "Updated OGOMt Training Shift",
                    note: "#{current_user.name} Updated OGOMt Training shift #{shift_str} for user: #{training_user.name} Updated by: #{current_user.name} (#{trainer_string})")
  end

  def delete_training_shift(shift)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    trainer_string = shift.is_trainer ? "Trainer" : "Trainee"
    ShiftLog.create(change_date: DateTime.now, user_id: current_user.id,
                    shift_id: shift.id, action_taken: "Deleted OGOMt Training Shift",
                    note: "#{current_user.name} Deleted OGOMt Training shift #{shift_str} Updated by: #{current_user.name} (#{trainer_string})")
  end
end
