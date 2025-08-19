# frozen_string_literal: true

module Filterable
  attr_accessor :resource

  include SessionKeyable

  COMMON_PARAMS = [ :limit, :page, :clear, :q, :format, { sort: [] } ].freeze
  COMMON_FILTERS = %w[action controller page clear format limit sort].freeze

  def filter!(resource, store: true, **)
    @resource = resource
    @store = store

    raise ArgumentError, "Must define FILTER_PARAMS in #{@resource}" unless @resource.const_defined?("FILTER_PARAMS")
    raise ArgumentError, "Must define filter function in #{@resource}" unless @resource.respond_to?(:filter)

    store!
    apply!(**)
  end

  # Optional custom session key for filters
  def set_filter_key(key)
    @custom_key = key
  end

  def filter_key
    @custom_key
  end

  def set_default_filters
    session[key] = {} unless session.key?(key)
    session[key].merge!(default_filters)
  end

  def table_length
    params[:limit] || filters&.dig("limit") || 25
  end

  def filters_and_sort
    @filters = uncommon_filters
    @sort = filters&.dig("sort") || []
  end

  protected

  def uncommon_filters
    filters&.except(*COMMON_FILTERS)&.inject({}) do |acc, (key, value)|
      if value.blank? || value == "unset"
        acc
      else
        acc.merge(key => value)
      end
    end
  end

  def filters
    @store ? session[key] : @filters
  end

  private

  def key
    session_key(@resource, suffix: "filters")
  end

  def store!
    unless @store
      @filters = filter_params_for
      return
    end

    if params[:clear] == "true"
      session[key] = {}
    else
      session[key] = {} unless session.key?(key)
      session[key].merge!(filter_params_for)
    end
  end

  def default_filters
    @resource.const_defined?("DEFAULT_FILTERS") ? @resource::DEFAULT_FILTERS : {}
  end

  def filter_params_for
    params.permit(@resource::FILTER_PARAMS + Filterable::COMMON_PARAMS).except(:clear).to_h.transform_values do |value|
      value == "unset" || value.blank? ? nil : value
    end
  end

  def apply!(**)
    resource.filter(filters, **)
  end
end
