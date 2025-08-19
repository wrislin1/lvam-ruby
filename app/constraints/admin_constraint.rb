class AdminConstraint
  attr_reader :user

  def initialize(request)
    @user = request.env["warden"].user
  end

  def self.matches?(request)
    new(request).authorized?
  end

  def authorized?
    user.present? && user.admin?
  end
end
