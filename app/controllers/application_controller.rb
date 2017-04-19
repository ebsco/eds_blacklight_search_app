class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  def after_sign_in_path_for(resource)
    if session[:current_url].present?
      session[:current_url]
    else
      root_path
    end
  end

  layout 'blacklight'

  protect_from_forgery with: :exception
end
