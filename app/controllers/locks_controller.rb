class LocksController < ApplicationController
  def index
    locks_scope = Lock.all
    if params[:filter] && !params[:filter].empty?
      locks_scope = locks_scope.like(params[:filter])
    end

    @locks = smart_listing_create :locks, locks_scope, partial: "locks/list",
      default_sort: {namespace: "asc", resource: "asc"}
  end

  def new
    @lock = Lock.new
  end

  def create
    new_params = lock_params
    @lock = Lock.new(new_params)
    if @lock.save skip_transaction: true
      @persisted = true
    else
      @errors = @lock.errors.full_messages
      render status: :bad_request
    end
  rescue ActiveRecord::RecordNotUnique
    # try to update existing record in case it has expired
    update_params = {
      owner: new_params[:owner],
      expires: new_params[:expires]
    }
    num_updated = Lock.
      where(namespace: new_params[:namespace],
            resource: new_params[:resource]).
      where("expires < ?", Time.now).
      update_all(update_params)
    case num_updated
    when 1
      @persisted = true
    when 0
      @persisted = false
      @errors = [%Q{lock on "#{new_params[:namespace]}" / "#{new_params[:resource]}" already exists and non-expired}]
      render status: :conflict
    else
      # this should be impossible
      raise "Unicorns ate the unique database index?"
    end
  rescue => e
    @errors = [e.inspect]
    render status: :internal_server_error
  end

  def edit
    @lock = Lock.find(params[:id])
  end

  def update
    if params[:id] && auth_admin?
      # allow any valid change but concurrency unsafe
      @lock = Lock.find(params[:id])
      if @lock.update(lock_params)
        @persisted = true
      else
        @errors = @lock.errors.full_messages
        render status: :bad_request
      end
    else
      # for non-admin allow only updating reservation time to prevent
      # lock stealing and other mistakes
      update_params = lock_params
      @lock = Lock.new(update_params)
      num_updated = Lock.
        where(owner: update_params[:owner],
              namespace: update_params[:namespace],
              resource: update_params[:resource]).
        update_all(expires: update_params[:expires],
                   updated_at: Time.now)

      if num_updated == 1
        @persisted = true
      elsif num_updated == 0
        # concurrency issue or not matching owner/resource specification
        @persisted = false
        @errors = ["conflict with existing lock or not matching namespace/resource/owner"]
        render status: :conflict
      else
        # this should be impossible
        raise "Unicorns ate the unique database index?"
      end
    end
  rescue ActiveRecord::RecordNotUnique
    @errors = [%Q{lock already exists}]
    render status: :conflict
  rescue => e
    @errors = [e.inspect]
    render status: :internal_server_error
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
    if params[:lock][:expires].kind_of?(String) &&
        params[:lock][:expires] =~ /^(\d+)([smhd])?$/ ||
        params[:lock][:expires].kind_of?(Numeric)
      # using duration notation
      count = $1 ? Integer($1) : params[:lock][:expires]
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
    elsif params[:lock][:expires].kind_of?(String)
      params[:lock][:expires] = Time.parse params[:lock][:expires]
    end

    params.require(:lock).permit(:namespace, :resource, :expires, :owner)
  end
end
