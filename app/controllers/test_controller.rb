class TestController < ApplicationController
  skip_before_action :authz!, only: [:health]

  # def pry
  #  # pry not loaded in dev environment so no need to protect this call
  #  binding.pry
  #end

  def health
    # TODO: check auth is configured and mongo is accessible
    # render :no_content
  end
end
