class LocksController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  def index
    # users_scope = User.active

    # Apply the search control filter.
    # Note: `like` method here is not built-in Rails scope. You need to define it by yourself.
    #locks_scope = users_scope.like(params[:filter]) if params[:filter]

    # Apply the credit card checkbox filter
    # users_scope = users_scope.with_credit_card if params[:with_credit_card] == "1"

    locks_scope = Lock.all
    locks_scope = locks_scope.like(params[:filter]) if params[:filter]

    @locks = smart_listing_create :locks, locks_scope, partial: "locks/list",
      default_sort: {namespace: "asc", resource: "asc"}
  end

  def new
    # TODO: can we have thid object created only once per server?
    @lock = Lock.new
  end

  def create
    @lock = Lock.create(lock_params)
  end

  def edit
    @lock = Lock.find(params[:id])
  end

  def update
    # puts params
    @lock = Lock.find(params[:id])

    @lock.update(lock_params)
  end

  def destroy
    @lock = Lock.find(params[:id])
    @lock.destroy
  end

  private

  def find_lock
    @lock = Lock.find(params[:id])
  end

  def lock_params
    if params[:lock][:expires] =~ /(\d+)([smhd])?/
      # using duration notation
      count = Integer($1)
      case $2
      when nil, "s"
        # count = count
      when "m"
        count = count * 60
      when "h"
        count = count * 60 * 60
      when "d"
        count = count * 60 * 60 * 24
      end
      params[:lock] = params[:lock].merge({expires: Time.now + count})
    end

    params.require(:lock).permit(:namespace, :resource, :expires, :owner)
  end
end
