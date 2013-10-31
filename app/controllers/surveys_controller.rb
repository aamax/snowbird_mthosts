class SurveysController < ApplicationController
  require "json"

  respond_to :html, :json, :js
  load_and_authorize_resource :except => [:show]

  def index
    @surveys = []
    users = User.active_users
    users.map do |u|
      name_array = u.name.split(' ')
      u.name = "#{name_array[-1]}, #{name_array[0..-2].join(' ')}"
    end
    @hosts = users.sort { |a, b| a.name <=> b.name }

    @hosts.each do |u|
      @surveys << Survey.total_row(u)
    end
  end

  def show
    # show entries for host
    user = User.find_by_id(params[:id])
    @surveys = user.surveys.sort {|a, b|  a.date <=> b.date }
  end

  # update, destroy, create, new, edit
end
