class GalleriesController < ApplicationController
  load_and_authorize_resource

  def index
    if current_user.has_role? :admin
      redirect_to gallery_page_path
    else
      @galleries = Gallery.all
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @galleries }
      end
    end
  end

  def gallery_page
    if current_user.has_role? :admin
      @galleries = Gallery.all
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @galleries }
      end
    else
      redirect_to :galleries_path
    end
  end

  def show
    @gallery = Gallery.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @gallery }
    end
  end

  def new
    @gallery = Gallery.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @gallery }
    end
  end

  def edit

  end

  def update
    @gallery = Gallery.find(params[:id])

    respond_to do |format|
      unless @gallery.update_attributes(params[:gallery])
        format.html { render action: "edit" }
        format.json { render json: @gallery.errors, status: :unprocessable_entity }
      else
        if current_user.has_role? :admin
          redirect_to gallery_page_path
        else
          redirect_to galleries_path
        end
      end
    end
  end

  def create
    @gallery = Gallery.new(params[:gallery])
    unless @gallery.save
      render :new
    else
      current_user.galleries << @gallery

      if current_user.has_role? :admin
        redirect_to gallery_page_path
      else
        redirect_to galleries_path
      end
    end
  end

  def destroy
    @gallery = Gallery.find(params[:id])
    @gallery.destroy
    if current_user.has_role? :admin
      redirect_to gallery_page_path
    else
      redirect_to galleries_path
    end
  end
end
