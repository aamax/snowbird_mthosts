class SurveysController < ApplicationController
  require "json"

  respond_to :html, :json, :js
  load_and_authorize_resource :except => [:show]

  def index
    @surveys = Survey.all
    #
    #users = User.active_users
    #users.map do |u|
    #  name_array = u.name.split(' ')
    #  u.name = "#{name_array[-1]}, #{name_array[0..-2].join(' ')}"
    #end
    #@surveys = users.sort { |a, b| a.name <=> b.name }
    respond_with @surveys
  end

  def show
    # show entries for host
    user = User.find_by_id(params[:id])
    @surveys = user.surveys.sort {|a, b|  a.date <=> b.date }
  end

  def create
    @survey = Survey.create(user_id: params[:user_id], date: params[:date], type1: params[:type1], type2: params[:type2])
    respond_with @survey
  end

  def update
    @survey = nil

  end

  # update, destroy, create, new, edit
end
