module SynchroParser
  class Intersection
    attr_reader :name, :date, :file_type

    def initialize(name:, date:, file_type:)
      @name = name
      @date = date
      @file_type = file_type
      @metrics = {}
      @los = nil
      @control_delay = nil
      @intersection_type = ""
    end

    def add_los(los)
      @los = los
    end

    def add_control_delay(control_delay)
      @control_delay = control_delay
    end

    def los
      @los
    end

    def control_delay
      @control_delay
    end

    # Adds a new metric with associated directional values to this intersection
    def add_metric(metric_name, values)
      @metrics[metric_name] = values
    end

    # Checks if a specific metric exists for this intersection
    def has_metric?(metric_name)
      @metrics.key?(metric_name)
    end

    # Retrieves the value for a specific direction and metric
    # Raises ParseError if the metric does not exist
    def get_value(direction, metric_key)
      metric = @metrics[metric_key]
      unless metric
        raise ParseError, "Metric '#{metric_key}' not found for intersection #{@name}"
      end

      metric[direction]
    end

    def metrics
      @metrics
    end

    def intersection_type
      @type
    end

    def set_intersection_type(type)
      @type = type
    end
  end
end
