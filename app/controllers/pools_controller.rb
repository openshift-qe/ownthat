class PoolsController < ApplicationController
  def index
    pools_scope = Pool.all
    if params[:filter] && !params[:filter].empty?
      pools_scope = pools_scope.like(params[:filter])
    end

    @pools = smart_listing_create :pools, pools_scope, partial: "pools/list",
      default_sort: {name: "asc", resource: "asc"}
  end

  def new
    @pool = Pool.new
    @pool.active = true
  end

  def create
    new_params = pool_params
    @pool = Pool.new(new_params)
    @pool.active = new_params[:active] == "true"
    unless @pool.save
      @errors = @pool.errors.full_messages
      render status: :bad_request
    end
  rescue
    handle_error($!)
  end

  def edit
    @pool = Pool.find(params[:id])
  rescue
    handle_error($!)
  end

  def update
    @pool = Pool.find(params[:id])
    new_params = pool_params
    new_params[:active] = new_params.has_key?(:active) && new_params[:active] == "true"
    unless @pool.update(new_params)
      @errors = @pool.errors.full_messages
      render status: :bad_request
    end
  rescue
    handle_error($!)
  end

  def destroy
    @pool = Pool.find(params[:id])
    @pool.destroy
  rescue
    handle_error($!)
  end

  private
  def pool_params
    params.require(:pool).permit(:name, :resource, :active, :note)
  end

  def handle_error(e)
    @errors = [e.inspect]
    log_error(e)
  end
end
