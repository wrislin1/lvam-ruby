module ApplicationHelper
  def page_title(page_title)
    str = "LVAM | #{page_title}"
    content_for :page_title, str
  end

  def navbar_links
    ret = []
    if current_page?(root_path)
      ret << {
        name: "How It Works",
        path: "#how-it-works"
      }
      ret << {
        name: "Features",
        path: "#features"
      }
      ret << {
        name: "Pricing",
        path: "#pricing"
      }
    end
    if user_signed_in?
      ret << {
        name: "Reports",
        path: reports_path
      }
    end
    ret
  end

  def admin_links
    ret = []
    if policy(User).index?
      ret << {
        name: "Users",
        icon: "fa-users",
        path: admin_users_path,
        active: admin_route? && controller_name == "users"
      }
    end
    ret
  end

  def admin_route?
    controller_path.include? "admin/"
  end

  def devise_links
    ret = []
    ret << {
      label: "Already a member? Log in",
      path: new_session_path(resource_name)
    } if controller_name != "sessions"
    if devise_mapping.registerable? && controller_name != "registrations"
      ret << { label: "Sign up", path: new_registration_path(resource_name) }
    end
    if devise_mapping.recoverable? && controller_name != "passwords" && controller_name != "registrations"
      ret << {
        label: "Forgot your password?",
        path: new_password_path(resource_name),
        icon: "fa-shield-exclamation"
      }
    end
    if devise_mapping.confirmable? && controller_name != "confirmations"
      ret << {
        label: "Didn't receive confirmation instructions?",
        path: new_confirmation_path(resource_name)
      }
    end
    if devise_mapping.lockable? && resource_class.unlock_strategy_enabled?(:email) && controller_name != "unlocks"
      ret << {
        label: "Didn't receive unlock instructions?",
        path: new_unlock_path(resource_name)
      }
    end
    if devise_mapping.omniauthable?
      resource_class.omniauth_providers.each do |provider|
        ret << {
          label: "Sign in with #{OmniAuth::Utils.camelize(provider)}",
          path: omniauth_authorize_path(resource_name, provider),
          data: { turbo: false }
        }
      end
    end
    ret
  end

  def account_tabs
    [
      {
        label: "Account",
        icon: "fa-gear",
        active: controller_name == "registrations",
        path: edit_user_registration_path
      },
      {
        label: "Subscription",
        icon: "fa-file-invoice-dollar",
        active: controller_name == "users" && action_name == "subscription",
        path: subscription_path
      }
    ].freeze
  end
end
