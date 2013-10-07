class SysConfigsController < ApplicationController
  load_and_authorize_resource

  def edit
  end

  def update
    if @sys_config.update_attributes(params[:sys_config])
      flash[:success] = "Configurations updated."

      redirect_to root_path
      return
    else
      @title = "Edit System Configurations"
      flash[:failure] = "ERROR: system configurations not updated."
      render 'edit'
      return
    end

  end
end
