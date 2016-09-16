class ApplicationController < ActionController::Base
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  include AuthHelper

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authz!
end
