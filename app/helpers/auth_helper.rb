require 'json'

module AuthHelper
  def authz!
    authenticate_with_http_basic do |user, password|
      @authz_role = AuthHelper.role(user, password)
      authorize_role!
    end
    return !!authz_role # make sure we found a role
  end

  def authz_again!
    request_http_basic_authentication
  end

  def authz_role
    @authz_role || authz_again!
  end

  def authz_forbidden!
    render file: "public/403", layout: false, status: :forbidden
  end

  def authorize_role!
    case authz_role
    when nil
      authz_again!
    when :admin
      return nil
    when :user
      params = request.filtered_parameters
      if params["controller"] == "locks" &&
          ["create", "update", "lock_from_pool"].include?(params["action"])
        return nil
      else
        logger.warn "regular user calling forbidden methods"
        authz_forbidden!
      end
    else
      logger.warn "unhandled user role #{authz_role}"
      authz_forbidden!
    end
  end

  def auth_admin?
    authz_role == :admin
  end

  def auth_user?
    authz_role == :user
  end

  def self.role(user, password)
    authz_db.each do |role, users|
      users.each do |u, p|
        return role.to_sym if u == user && p == password
      end
    end
  end

  private_class_method def self.authz_db
    @authz_db ||= load_rules
  end

  private_class_method def self.load_rules
    @rules ||= JSON.parse(ENV['AUTHZ_DB'])
  rescue => e
    raise "bad authentication data configured for app"
  end
end
