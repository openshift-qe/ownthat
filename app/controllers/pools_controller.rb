class PoolsController < ApplicationController
  def index
    pools_scope = Pool.all
    if params[:filter] && !params[:filter].empty?
      pools_scope = pools_scope.like(params[:filter])
    end

    @pools = smart_listing_create :pools, pools_scope, partial: "pools/list",
      default_sort: {name: "asc", resource: "asc"}
  end

  def create
    new_params = pool_params
    @pool = Pool.new(new_params)
    unless @pool.save
      @errors = @pool.errors.full_messages
      render status: :bad_request
    end
  end

  def pool_params
    params.require(:lock).permit(:name, :resource, :active, :note)
  end
end
