# == Schema Information
#
# Table name: sys_configs
#
#  id                :integer          not null, primary key
#  season_year       :integer
#  group_1_year      :integer
#  group_2_year      :integer
#  group_3_year      :integer
#  season_start_date :date
#  bingo_start_date  :date
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  shift_count       :integer
#

class SysConfigsController < ApplicationController
  load_and_authorize_resource

  def edit
  end

  def update
    if @sys_config.update_attributes(params[:sys_config])
      flash[:success] = "Configurations updated."

      redirect_to edit_sys_config_path(SysConfig.first)
      return
    else
      @title = "Edit System Configurations"
      flash[:failure] = "ERROR: system configurations not updated."
      render 'edit'
      return
    end

  end
end
