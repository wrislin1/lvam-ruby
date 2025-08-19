# frozen_string_literal: true

class Column
  attr_accessor :id, # Id of the column (required)
                :label, # Text for column header (default: id.titleize)
                :func, # How to transform obj into data (default: obj.send(id))
                :icon, # Icon to display in column header
                :fallback, # If func isn't sent and obj doesn't respond to id, use this function instead
                :template, # Partial to render for this column's value
                :sortable, # Is it sortable?
                :sort_key, # What should we sort on? (default: id, optional)
                :classes, # Classes to add to the column
                :sm_label, # Text for column header on small screens
                :toggleable # Can this column be toggled on/off?

  def initialize(id, params = {})
    @id = id.to_sym if id.is_a? String
    @id = id if id.is_a? Symbol
    raise "id is required to define a Column" if id.blank?

    @label = params.fetch(:label, @id.to_s.titleize)
    @func = params.fetch(:func, nil)
    @fallback = params.fetch(:fallback, ->(x) { x })
    @template = params.fetch(:template, nil)
    @sortable = params.fetch(:sortable, true)
    @classes = params.fetch(:classes, "")
    @sm_label = params.fetch(:sm_label, nil)
    @sort_key = params.fetch(:sort_key, @id.to_s)
    @icon = params.fetch(:icon, nil)
    @toggleable = params.fetch(:toggleable, true)
  end

  def value_for(rec)
    if func.present?
      begin
        ret = func.call(rec)
      rescue StandardError => e
        raise e if fallback.blank?

        ret = fallback.call(rec)
      end
    else
      ret = rec.respond_to?(id) ? rec.send(id) : fallback.call(rec)
    end

    ret
  end

  def to_hash
    { label:,
      func:,
      fallback:,
      template:,
      sortable:,
      sort_key:,
      classes:,
      id:,
      sm_label:,
      toggleable: }
  end

  def to_s
    "Column{#{to_hash.to_json}}"
  end
end
