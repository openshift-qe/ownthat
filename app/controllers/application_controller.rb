class ApplicationController < ActionController::Base
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  include AuthHelper

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authz!

  def log_error(exception)
    logger.error(
      "\n\n#{exception.class} (#{exception.message}):\n" +
      Rails.backtrace_cleaner.clean(exception.backtrace).join("\n") +
      "\n"
    )
  end
end
