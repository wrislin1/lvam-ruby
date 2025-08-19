module Admin::UsersHelper
  def user_actions(user)
    ret = []
    if policy(user).edit?
      ret << {
        name: "Edit",
        icon: "fa-edit",
        path: edit_admin_user_path(user),
        turbo: true
      }
    end
    if policy(user).show?
      ret << {
        name: "View",
        icon: "fa-user",
        path: admin_user_path(user),
        turbo: false,
        turbo_frame: "_top"
      }
    end
    ret
  end
end
