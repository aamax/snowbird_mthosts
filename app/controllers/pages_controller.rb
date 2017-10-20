# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PagesController < ApplicationController
  # before_filter :authenticate_user!

  def show
    pg_id = params[:id]
    if current_user
      pg_id ||= 'home'
      @title = pg_id
      if ((pg_id == 'admin') && (!current_user.has_role? :admin))
        redirect_to root_path, :alert => "you do not have permission to access this page"
      else
        render "/pages/#{pg_id}"
      end
    else
      pg_id ||= 'public'
      @title = pg_id
      if ((pg_id == 'admin') || (pg_id == 'home'))
        redirect_to root_path, :alert => "you do not have permission to access this page"
      else
        render "/pages/#{pg_id}"
      end
    end
  end

  def show_contact_info
    if !current_user.blank?
      @userlist = User.active_users.sort {|a,b| a.name <=> b.name }
      @title = "Host Contact Info"
    end
  end

  def edit
    if params[:id] == 'aamax'
      @page = Page.find_by_name('aamax')
    else
      redirect_to root_path
    end
  end

  def update
    @page = Page.find(params[:id])
    unless @page.update_attributes(params[:page])
      render :edit, :alert => "Error saving record: #{@page.errors.full_messages}"
    else
      redirect_to root_path
    end
  end

end
