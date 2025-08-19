module Admin
  class UsersController < ApplicationController
    include Filterable
    include ColumnCustomizable
    before_action :set_user, only: %i[subscription show edit update destroy]
    before_action :set_index_crumb

    def column_defs
      [
        Column.new(:id, label: "ID", sort_key: "users.id", icon: "fa-hashtag", toggleable: false),
        Column.new(:email, icon: "fa-at"),
        Column.new(:name, sort_key: "last_name", icon: "fa-pencil"),
        Column.new(:subscription_status, label: "Subscribed", sort_key: "subscription_status", template: "subscription_status", icon: "fa-credit-card"),
        Column.new(:admin, template: "admin", icon: "fa-shield-halved"),
        Column.new(:status, sort_key: "users.status", func: ->(x) { x.status.titleize }, icon: "fa-circle-check"),
        *TableHelper.updated_created_cols(updated_sort_key: "users.updated_at", created_sort_key: "users.created_at"),
        Column.new(:actions, label: "", template: "actions", toggleable: false, sortable: false),
      ].freeze
    end

    def index
      authorize User
      params[:sort] = [ "users.updated_at:desc" ] if params[:sort].blank?
      paginate_users
      filters_and_sort
    end

    def edit
      add_breadcrumb "Edit #{@user.name.presence || @user.email}"
    end

    def update
      if @user.update user_params
        render turbo_stream: [
          close_modal(id: "user-modal"),
          stream_success_alert("User updated!"),
          render_row
        ]
      else
        render turbo_stream: [
          stream_error_alert("Error updating user!"),
          render_form
        ], status: :unprocessable_entity
      end
    end

    def destroy
    end

    def new
      @user = User.new
      authorize @user
    end

    def create
      @user = User.new user_params
      authorize @user
      @user.skip_password_validation = true
      if @user.valid? && @user.invite!(current_user)
        msg = "User created! An invitation email has been sent to #{@user.email}."
        respond_to do |format|
          format.html do
            redirect_to admin_users_path, notice: msg
          end
          format.turbo_stream do
            render turbo_stream: [
              close_modal(id: "user-modal"),
              stream_success_alert(msg),
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            render :new
          end
          format.turbo_stream do
            render turbo_stream: [
              stream_error_alert(@user.errors.full_messages.join(", ")),
              render_form
            ], status: :unprocessable_entity
          end
        end
      end
    end

    def show
      add_breadcrumb @user.name
    end

    def subscription
      @subscriptions = StripeAdmin.get_user_subscriptions(@user, status: "all", expand: %w[data.latest_invoice]).data
      @products = StripeAdmin.get_products.data
    end

    private

    def render_row
      turbo_stream.replace(
        @user,
        partial: "admin/users/user",
        locals: { user: @user }
      )
    end

    def render_form
      turbo_stream.replace(
        helpers.dom_id(@user, :form),
        partial: "admin/users/form"
      )
    end

    def user_params
      params.require(:user).permit(:email, :admin, :first_name, :last_name, :status)
    end

    def set_user
      @user = User.find params[:id]
      authorize @user
    end

    def set_index_crumb
      add_breadcrumb "Users", path: admin_users_path
    end

    def paginate_users
      @scope = User
      @pagy, @users = pagy(filter!(User))
    end
  end
end
