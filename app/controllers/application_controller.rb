class ApplicationController < ActionController::Base
#  include SmartListing::Helper::ControllerExtensions
#  helper  SmartListing::Helper

  include AuthHelper

  protect_from_forgery with: :exception
  before_action :authz!
end
