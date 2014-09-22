class SurveysController < ApplicationController
  require "json"
  require 'csv'

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
    @user = User.find_by_id(params[:id])
    @surveys = @user.surveys.sort {|a, b|  a.date <=> b.date }
  end

  def create
    @survey = Survey.create(user_id: params[:user_id], date: params[:date], type1: params[:type1], type2: params[:type2])
    respond_with @survey
  end

  def edit

  end

  def update
    @survey = Survey.find(params[:id])
    if @survey.update_attributes(params[:survey])
      flash[:success] = "Survey Count updated."
      redirect_to "/surveys/#{@survey.user_id}"
    else
      flash[:failure] = "ERROR: Survey Count NOT updated."
      render :action => "edit"
    end
  end

  def destroy
    user = User.find(Survey.find(params[:id]).user_id)
    if Survey.destroy(params[:id])
      redirect_to "/surveys/#{user.id}", notice: "Survey Count deleted"
    else
      redirect_to surveys_path, alert: "Unable to Delete Suvey Count Entry: #{@survey.errors.messages}"
    end
  end

  def delete_surveys
    Survey.delete_all
    redirect_to :back, :notice => "All Surveys Have Been Deleted"
  end

  def survey_list(user_id, surveys, dates)
    arr = []
    dates.each do |h|
      arr << 0
    end
    idx = -1
    surveys.each do |s|
      if s.user_id == user_id.to_i
        dates.each_with_index do |item, index|
          idx = index if item == s.date
        end
        arr[idx] = s.type1 if idx != -1
      end
    end
    arr
  end

  def export_to_csv
    @surveys = Survey.all.sort {|a,b| a.date <=> b.date }

    if @surveys.empty?
      respond_with "no data"
    else
      dates = []
      names = User.all.map {|u| "#{u.id},#{u.name}" }

      @surveys.each do |s|
        dates << s.date unless dates.include? s.date
      end
      dates.sort!
      header = "Name," + dates.map {|d| d.strftime('%Y%m%d')}.join(',')

      csv_string = CSV.generate do |csv|
        csv << header.split(',')

        names.each do |n|
          arr = [n.split(',')[1]] + survey_list(n.split(',')[0], @surveys, dates)

          csv << arr
        end
      end
    end
    send_data csv_string,
              :type => "text/csv; charset:iso-8859-1;header=present",
              :disposition => "attachment; filename=csv_survey_export#{Date.today.strftime('%Y%m%d')}.csv"
    end
end
