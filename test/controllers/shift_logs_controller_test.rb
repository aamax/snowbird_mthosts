# == Schema Information
#
# Table name: shift_logs
#
#  id           :integer          not null, primary key
#  change_date  :datetime
#  user_id      :integer
#  shift_id     :integer
#  action_taken :string
#  note         :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "test_helper"

class ShiftLogsControllerTest < ActionController::TestCase
  def shift_log
    @shift_log ||= shift_logs :one
  end

  def test_index
    get :index
    assert_response :success
    assert_not_nil assigns(:shift_logs)
  end

  def test_new
    get :new
    assert_response :success
  end

  def test_create
    assert_difference("ShiftLog.count") do
      post :create, shift_log: { action_taken: shift_log.action_taken, change_date: shift_log.change_date, note: shift_log.note, shift_id: shift_log.shift_id, user_id: shift_log.user_id }
    end

    assert_redirected_to shift_log_path(assigns(:shift_log))
  end

  def test_show
    get :show, id: shift_log
    assert_response :success
  end

  def test_edit
    get :edit, id: shift_log
    assert_response :success
  end

  def test_update
    put :update, id: shift_log, shift_log: { action_taken: shift_log.action_taken, change_date: shift_log.change_date, note: shift_log.note, shift_id: shift_log.shift_id, user_id: shift_log.user_id }
    assert_redirected_to shift_log_path(assigns(:shift_log))
  end

  def test_destroy
    assert_difference("ShiftLog.count", -1) do
      delete :destroy, id: shift_log
    end

    assert_redirected_to shift_logs_path
  end
end
