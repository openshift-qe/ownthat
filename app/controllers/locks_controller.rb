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

  def lock_from_pool
    @persisted = false
    new_params = lock_params

    pool_name = new_params.delete(:poolname)
    unless pool_name
      @errors = ["pool name not specified in request"]
      render :create, status: :bad_request
      return
    end
    r_namespace = new_params.delete(:namespace) || pool_name
    namespace = sqlquote(r_namespace)
    pool_name = sqlquote(pool_name)
    r_expires = new_params.delete(:expires)
    expires = r_expires.utc.to_s(:db) if Time === r_expires
    expires = sqlquote(expires)
    r_now = Time.now
    now = sqlquote(r_now.utc.to_s(:db))
    # now_fake is a hack to let us obtain exact resource used later
    r_now_fake = r_now - rand(10000)
    now_fake = sqlquote(r_now_fake.utc.to_s(:db))
    r_owner = new_params.delete(:owner)
    owner = sqlquote(r_owner)

    begin
      insert_sql = <<-SQL
      INSERT INTO #{Lock.table_name}
        (namespace, resource, expires, owner, created_at, updated_at)
      SELECT
        #{namespace}, resource, #{expires}, #{owner}, #{now}, #{now_fake}
      FROM #{Pool.table_name}
      WHERE
        name = #{pool_name} AND
        active = true AND
        resource NOT IN (
          SELECT resource FROM #{Lock.table_name}
          WHERE namespace = #{namespace}
        )
      LIMIT 1;
      SQL
      #Lock.connection.insert("INSERT INTO #{Lock.table_name} (namespace, resource, expires, owner, created_at, updated_at) select 'somens', resource, NOW(), 'someowner', NOW(), NOW() from #{Pool.table_name} where name = 'testpool' and active = true and resource not in (select resource from #{Lock.table_name} where namespace = 'somens') limit 1;")
      res = Lock.connection.insert(insert_sql)
    rescue ActiveRecord::RecordNotUnique
      # possibly a concurrency issue
      retry
    end

    if res == 0
      # create failed to find free records, try updating expired record
      update_sql = <<-SQL
      UPDATE #{Lock.table_name}
      SET
        owner = #{owner},
        expires = #{expires},
        created_at = #{now},
        updated_at = #{now_fake}
      WHERE
        namespace = #{namespace} AND
        expires < #{sqlquote(Time.now.utc.to_s(:db))} AND
        resource IN (
          SELECT resource
          FROM #{Pool.table_name}
          WHERE name = #{pool_name}
          )
      LIMIT 1;
      SQL

      res = Lock.connection.update(update_sql)
    end

    if res == 0
      # failed to find existing expired record, no other options to try
      @errors = [%Q{could not find free records from pool #{pool_name} for #{namespace} namespace. Or empty pool.} ]
      render :create, status: :conflict
      return
    end

    @lock = Lock.find_by!(
      namespace: r_namespace,
      expires: r_expires,
      owner: r_owner,
      created_at: r_now,
      updated_at: r_now_fake
    )

    @persisted = true
    render :create
  rescue => e
    @errors = [e.inspect]
    render :create, status: :internal_server_error
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

    if params[:poolname]
      params[:lock][:poolname] ||= params[:poolname]
    end

    if params[:lock][:resource] && params[:lock][:poolname]
      raise "poolname and resource specified simultaneously"
    end

    params.require(:lock).permit(:namespace, :resource, :expires, :owner, :poolname)
  end

  def sqlquote(str)
    Lock.connection.quote str
  end
end
