class User < ApplicationRecord
  include PgSearch::Model
  attr_accessor :skip_password_validation

  devise :invitable,
         :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable
  validates :email, presence: true, 'valid_email_2/email': true
  validates :first_name, :last_name, presence: true
  has_many :user_subscriptions, dependent: :restrict_with_exception
  has_many :reports, dependent: :destroy
  has_many :user_downloads, dependent: :destroy
  enum :status, {
    active: "active",
    archived: "archived",
    blocked: "blocked"
  }
  pg_search_scope :by_term,
                  against: %i[email],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.1 }
                  }
  scope :by_admin, ->(admin) { where(admin:) }
  scope :by_status, ->(status) { where(status:) }
  scope :by_subscription_status, ->(status) {
    w_joins = left_joins(:user_subscriptions)
    case status
    when "active"
      w_joins.where("user_subscriptions.status = 'active'")
    when "trialing"
      w_joins.where("user_subscriptions.status = 'trialing'")
    else
      w_joins.where("user_subscriptions.id IS NULL")
    end
  }
  FILTER_PARAMS = %w[admin status subscription_status].freeze
  SORTABLE_COLS = %w[users.id users.status email users.created_at users.updated_at first_name last_name admin].freeze

  def active_for_authentication?
    active? && super
  end

  def name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def self.faceted_search_user_type_options(selected = [], count_scope: nil)
    counts = count_scope&.group(:admin)&.count
    [ true, false ].map do |x|
      {
        value: x.to_s,
        label: x ? "Admin" : "Non-admin",
        selected: selected.include?(x.to_s),
        count: counts&.dig(x)
      }
    end
  end

  def self.faceted_search_status_options(selected = [], count_scope: nil)
    counts = count_scope&.group("users.status")&.count
    User.statuses.values.map do |s|
      {
        value: s,
        label: s.titleize,
        selected: selected.include?(s),
        count: counts&.dig(s)
      }
    end
  end

  def self.faceted_search_subscription_status_options(selected = [])
    [
      {
        value: "active",
        label: "Active",
        selected: selected.include?("active")
      },
      {
        value: "trialing",
        label: "Trial",
        selected: selected.include?("trialing")
      },
      {
        value: "none",
        label: "None",
        selected: selected.include?("none")
      }
    ]
  end

  def self.filter(params)
    q, sort, admin, subscription_status, status = params.values_at "q", "sort", "admin", "subscription_status", "status"
    query = User.select(
      [
        "users.*",
        "CASE WHEN active_us.id IS NOT NULL THEN 'active' ELSE (CASE WHEN trial_us.id IS NOT NULL THEN 'trialing' ELSE NULL END) END AS subscription_status",
      ].join(", ")
    ).joins(
      [
        "LEFT JOIN (SELECT DISTINCT ON (user_id) * FROM user_subscriptions us WHERE us.status = 'active' ORDER BY us.user_id, us.created_at DESC) active_us ON active_us.user_id = users.id",
        "LEFT JOIN (SELECT DISTINCT ON (user_id) * FROM user_subscriptions us WHERE us.status = 'trialing' ORDER BY us.user_id, us.created_at DESC) trial_us ON trial_us.user_id = users.id",
      ].join(" ")
    )
    query = query.merge(User.by_term(q)) if q.present?
    query = query.merge(User.by_subscription_status(subscription_status)) if subscription_status.present?
    query = query.merge(User.by_admin(true)) if admin == "true"
    query = query.merge(User.by_admin(false)) if admin == "false"
    query = query.merge(User.by_status(status)) if status.present?
    query = query.order Arel.sql(TableHelper.sort_str(sort, SORTABLE_COLS)) if sort.present?
    query.group(
      [
        "users.id",
        "active_us.id",
        "trial_us.id",
        *(q.present? ? [ "#{PgSearch::Configuration.alias('users')}.rank" ] : [])
      ].join(", ")
    )
  end

  def subscribed?
    return true if admin?

    StripeAdmin.get_user_subscriptions(self, status: nil)
               .any? { |s| %w[active trialing].include?(s.status) }.present?
  end

  protected

  def password_required?
    return false if skip_password_validation

    super
  end
end
