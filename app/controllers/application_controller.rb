class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception  # TODO may not work with rails 3.?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

end
