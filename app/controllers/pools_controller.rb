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
  end

  def edit
    @pool = Pool.find(params[:id])
  end

  def update
    @pool = Pool.find(params[:id])
    new_params = pool_params
    new_params[:active] = new_params.has_key?(:active) && new_params[:active] == "true"
    unless @pool.update(new_params)
      @errors = @pool.errors.full_messages
      render status: :bad_request
    end
  end

  def disable
    update_params = pool_params
    update_params[:active] = false
    @pool = Pool.new(update_params)
    num_disabled = Pool.
      where(       name: update_params[:name],
               resource: update_params[:resource]).
      update_all(active: update_params[:active],
             updated_at: Time.now)
    if num_disabled == 1
      @persisted = true
    elsif num_disabled == 0
      # concurrency issue or not matching name/resource specification
      @persisted = false
      @errors = ["conflict with existing pool or not matching name/resource"]
      render status: :conflict
    else
      # this should be impossible
      raise "Unicorns ate the unique database index?"
    end
  end

  def destroy
    @pool = Pool.find(params[:id])
    @pool.destroy
  end

  private
  def pool_params
    params.require(:pool).permit(:name, :resource, :active, :note)
  end
end
