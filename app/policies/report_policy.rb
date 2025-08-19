class ReportPolicy < ApplicationPolicy
  def index?
    user&.present?
  end

  def new?
    user&.subscribed?
  end

  def edit?
    return true if user&.admin?

    new? && record.user == user
  end
  alias update? edit?
  alias destroy? edit?
  alias show? edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user.present?
        scope.where(user:)
      else
        scope.none
      end
    end
  end
end
