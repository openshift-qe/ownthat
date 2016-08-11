class ApplicationController < ActionController::Base
#  include SmartListing::Helper::ControllerExtensions
#  helper  SmartListing::Helper

  protect_from_forgery with: :exception
end
