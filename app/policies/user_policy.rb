class UserPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end
  alias new? index?
  alias create? index?
  alias destroy? index?

  def edit?
    user&.admin? || user == record
  end
  alias update? edit?
  alias subscription? edit?
  alias show? edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user.present?
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end
end
