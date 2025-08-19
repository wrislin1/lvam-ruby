module SynchroParser
  class Report
    attr_reader :errors, :am_file, :pm_file

    def initialize(am_file = nil, pm_file = nil)
      @am_intersections = {}
      @pm_intersections = {}
      @errors = []
      @am_file = am_file
      @pm_file = pm_file

      # Process any provided files immediately upon initialization
      parse_and_compare
    end

    # Adds or replaces the AM file data and re-runs the parsing process
    def add_am_file(am_file)
      @am_file = am_file
      @am_intersections = {}
      parse(@am_file, "AM")
      update_report_comparison if @pm_file.present?
    end

    # Adds or replaces the PM file data and re-runs the parsing process
    def add_pm_file(pm_file)
      @pm_file = pm_file
      @pm_intersections = {}
      parse(@pm_file, "PM")
      update_report_comparison if @am_file.present?
    end

    # Provides access to all intersections with keys that include AM/PM designators
    # to distinguish between intersections with the same name from different files
    def intersections
      merged = {}
      @am_intersections.each do |name, intersection|
        merged["#{name} AM"] = intersection
      end
      @pm_intersections.each do |name, intersection|
        merged["#{name} PM"] = intersection
      end
      merged
    end

    def am_intersections
      @am_intersections
    end

    def pm_intersections
      @pm_intersections
    end

    # Retrieves metric values for a specific direction and metric type from either AM or PM data
    # Returns an array of hashes with intersection names and corresponding values
    def get_values(direction, metric_key, file_type)
      if file_type.downcase == "am"
        collect_metric_values(@am_intersections, direction, metric_key)
      elsif file_type.downcase == "pm"
        collect_metric_values(@pm_intersections, direction, metric_key)
      else
        raise SynchroParser::ParseError, "Invalid file type: #{file_type}"
      end
    end

    def get_value(intersection_name, direction, metric_key, file_type)
      if file_type.downcase == "am"
        intersection = @am_intersections[intersection_name]
      elsif file_type.downcase == "pm"
        intersection = @pm_intersections[intersection_name]
      else
        raise SynchroParser::ParseError, "Invalid file type: #{file_type}"
      end

      if intersection
        intersection.get_value(direction, metric_key)
      else
        raise SynchroParser::ParseError, "Intersection '#{intersection_name}' not found in #{file_type} data"
      end
    end

    # Helper method that extracts metric values from a collection of intersections
    # Returns results in a consistent format for client code
    def collect_metric_values(intersections, direction, metric_key)
      results = []
      intersections.each do |_, intersection|
        if intersection.has_metric?(metric_key)
          results << { name: intersection.name, value: intersection.get_value(direction, metric_key) }
        end
      end
      results
    end

    # Returns an array of hashes with intersection names and their LOS values
    def get_los_values(file_type)
      results = []

      if file_type.downcase == "am"
        @am_intersections.each do |_, intersection|
          results << { name: intersection.name, los: intersection.los }
        end
      elsif file_type.downcase == "pm"
        @pm_intersections.each do |_, intersection|
          results << { name: intersection.name, los: intersection.los }
        end
      else
        raise SynchroParser::ParseError, "Invalid file type: #{file_type}"
      end

      results
    end

    # Returns an array of hashes with intersection names and their control delay values
    def get_control_delay_values(file_type)
      results = []

      if file_type.downcase == "am"
        @am_intersections.each do |_, intersection|
          results << { name: intersection.name, control_delay: intersection.control_delay }
        end
      elsif file_type.downcase == "pm"
        @pm_intersections.each do |_, intersection|
          results << { name: intersection.name, control_delay: intersection.control_delay }
        end
      else
        raise SynchroParser::ParseError, "Invalid file type: #{file_type}"
      end

      results
    end

    private

    # Central method that handles file parsing and comparison
    # Ensures both operations happen together when files are updated
    def parse_and_compare
      parse(@am_file, "AM") if @am_file.present?
      parse(@pm_file, "PM") if @pm_file.present?
      update_report_comparison if @am_file.present? && @pm_file.present?
    end

    def update_report_comparison
      @errors = compare_reports(@am_intersections, @pm_intersections)
    end

    # Validates and processes a single Synchro file
    def parse(file_content, file_type)
      # Check if the file format appears valid
      unless valid_synchro_format?(file_content)
        @errors << "File #{file_type} does not appear to be a valid Synchro export."
        return
      end

      # Split file into intersection chunks
      intersections = extract_intersection_chunks(file_content)

      intersections.each do |content, _|
        parse_intersection(content, file_type)
      end
    end

    # Checks if the content appears to be a valid Synchro export
    def valid_synchro_format?(content)
      content.match?(/^\d+:/)
    end

    # Splits file content into chunks for each intersection
    def extract_intersection_chunks(file_content)
      chunks = file_content.split(/^(\d+):/).each_slice(2).to_a
      chunks.shift  # Remove the empty first element
      chunks
    end

    # Extracts intersection metadata and metrics from an intersection block
    def parse_intersection(content, file_type)
      first_line = content.lines.first
      name, date = first_line.split("\t")
      intersection_type = content.include?("Control Delay, s/veh") ? "Signalized" : "TWSC"
      intersection = Intersection.new(name: name.strip, date: date.strip, file_type: file_type)
      intersection.set_intersection_type(intersection_type)

      if intersection_type == "TWSC"
        control_delay = get_twsc_control_delay(content)
        los = control_delay ? get_los_from_delay(control_delay) : nil
        intersection.add_control_delay(control_delay) if control_delay
        intersection.add_los(los)
      end

      # Find and process metrics
      movement_data = find_movement_section(content)

      # Process metrics if we found the section and have data
      if movement_data[:movements].present? && movement_data[:metric_lines].present?
        process_metric_lines(movement_data[:movements], movement_data[:metric_lines], intersection)
      end

      if file_type == "AM"
        @am_intersections[name.strip] = intersection
      elsif file_type == "PM"
        @pm_intersections[name.strip] = intersection
      end
    end

    def get_twsc_control_delay(content)
      control_delay = nil
      content.lines[1..].each_with_index do |line, _|
        next if line.strip.empty?
        if line =~ /Int Delay, s\/veh/
          control_delay = line[36..].strip
          break
        end
      end
      control_delay&.to_f
    end

    def get_los_from_delay(delay)
      case delay
      when 0..10.0
        "A"
      when 10.1..20.0
        "B"
      when 20.1..35.0
        "C"
      when 35.1..55.0
        "D"
      when 55.1..80.0
        "E"
      else
        "F"
      end
    end

    # Locates the Movement row and associated data
    def find_movement_section(content)
      movements = nil
      metric_lines = nil

      content.lines[1..].each_with_index do |line, j|
        next if line.strip.empty?
        column = line.split(/\s+/).first

        if column =~ /Movement/
          movements = line[36..].split(/\s+/)
          metric_lines = content.lines[j + 2, content.lines.length]
          break
        end
      end

      { movements: movements, metric_lines: metric_lines }
    end

    # Process the metric lines using the original fixed-position method
    def process_metric_lines(movements, metric_lines, intersection)
      ending_index = nil
      metric_lines.each_with_index do |line, i|
        if line.strip.empty?
          ending_index = i
          break
        end

        # Extract metric name from first 36 characters
        column = line[0..35].strip

        # Extract values using fixed character positions for each direction
        values = extract_directional_values(line)

        # Remove key if it is not in the movements list
        values.delete_if { |k, _v| !movements.include?(k) }
        intersection.add_metric(column, values)
      end
      if intersection.intersection_type == "Signalized" && ending_index && metric_lines[ending_index..]
        metric_lines[ending_index..].each_with_index do |line, i|
          if line.strip.include? "Intersection Summary"
            if i + 2 < metric_lines[ending_index..].length
              control_delay = metric_lines[ending_index + i + 1].split("\t").last&.strip
              los = metric_lines[ending_index + i + 2].split("\t").last&.strip

              intersection.add_control_delay(control_delay) if control_delay
              intersection.add_los(los) if los
            end
            break
          end
        end
      end
    end

    # Extracts directional values from a single line of metric data
    def extract_directional_values(line)
      directions = %w[EBL EBT EBR WBL WBT WBR NBL NBT NBR SBL SBT SBR]
      values = {}
      directions.each_with_index do |direction, index|
        start_pos = 36 + index * 6
        values[direction] = line[start_pos, 6]&.strip
      end
      values
    end

    # Compares AM and PM reports to identify any missing intersections
    def compare_reports(report_am, report_pm)
      errors = []
      missing_in_am = report_pm.keys - report_am.keys
      missing_in_pm = report_am.keys - report_pm.keys

      errors << "Intersections missing in AM file: #{missing_in_am.join(', ')}" unless missing_in_am.empty?
      errors << "Intersections missing in PM file: #{missing_in_pm.join(', ')}" unless missing_in_pm.empty?
      errors
    end
  end
end
