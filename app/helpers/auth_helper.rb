require 'json'

module AuthHelper
  attr_reader :authz_role

  def authz!
    @authz_role = authenticate_with_http_basic do |user, password|
      AuthHelper.role(user, password)
    end
    authorize_role!
  end

  def authz_again!
    request_http_basic_authentication('OwnThat')
  end

  def authz_forbidden!
    render file: "public/403", layout: false, status: :forbidden
  end

  def authorize_role!
    case authz_role
    when nil
      authz_again!
    when :admin
      return
    when :user
      params = request.filtered_parameters
      if params["controller"] == "locks" &&
          ["create", "update", "lock_from_pool"].include?(params["action"]) ||
         params["controller"] == "pools" &&
          ["disable"].include?(params["action"])
        return
      else
        logger.warn "regular user calling forbidden methods"
        authz_forbidden!
      end
    else
      logger.warn "unhandled user role '#{authz_role}'"
      authz_forbidden!
    end
  end

  def auth_admin?
    authz_role == :admin
  end

  def auth_user?
    authz_role == :user
  end

  # using class methods/variables to avoid parsing auth db multiple times
  def self.role(user, password)
    authz_db.each do |role, users|
      return role.to_sym if users[user] == password
    end
    return nil
  end

  private_class_method def self.authz_db
    @authz_db ||= load_rules
  end

  private_class_method def self.load_rules
    JSON.parse(ENV['AUTHZ_DB'])
  rescue => e
    raise "bad authentication data configured for app"
  end
end
