module SynchroParser
  class IntersectionRenderer
    def self.render_intersection(name, index, intersection, pm_intersection)
      intersection_data = prepare_intersection_data(name, intersection, pm_intersection)

      am_los_class = intersection_data[:overall_am_los].present? ? "los-#{intersection_data[:overall_am_los].downcase}" : ""

      <<-HTML
        <div class="intersection-diagram-container">
          <div class="intersection-container">
            <div class="metrics-box">
              <div class="los-value #{am_los_class}">#{intersection_data[:overall_am_los]}(#{intersection_data[:overall_pm_los]})</div>
              <div class="delay-value">#{intersection_data[:control_delay_am]}(#{intersection_data[:control_delay_pm]})</div>
            </div>

            <!-- Intersection diagram -->
            <div class="intersection-diagram">
              <!-- SB approach -->
              <div class="approach-container top">
                #{render_approach_data_vertical('top', intersection_data)}
              </div>

              <!-- EB approach -->
              <div class="approach-container left">
                #{render_approach_data_horizontal('left', intersection_data)}
              </div>

              <!-- Circle with intersection number -->
              <div class="intersection-circle">
                <div class="intersection-number">#{index + 1}</div>
              </div>

              <!-- WB approach -->
              <div class="approach-container right">
                #{render_approach_data_horizontal('right', intersection_data)}
              </div>

              <!-- NB approach -->
              <div class="approach-container bottom">
                #{render_approach_data_vertical('bottom', intersection_data)}
              </div>
            </div>

            <div class="intersection-name">
              #{format_intersection_name(name)}
            </div>
          </div>
        </div>
      HTML
    end

    private

    def self.prepare_intersection_data(name, intersection, pm_intersection)
      # Extract overall LOS and control delay
      data = {
        name: name,
        overall_am_los: intersection.los || "N/A",
        overall_pm_los: pm_intersection&.los || "N/A",
        control_delay_am: intersection.control_delay || "N/A",
        control_delay_pm: pm_intersection&.control_delay || "N/A"
      }

      # Direction mappings
      dir_map = {
        "EB" => "left",
        "WB" => "right",
        "NB" => "bottom",
        "SB" => "top"
      }

      # Parse lane configurations
      data[:lane_config] = extract_lane_configurations(intersection, dir_map)

      # Volumes and LOS
      data[:movements] = extract_movement_data(intersection, pm_intersection, dir_map)

      data
    end

    def self.extract_lane_configurations(intersection, dir_map)
      lane_config = {}

      # Initialize lane configuration for all positions
      dir_map.each_value do |position|
        lane_config[position] = { "L" => "0", "T" => "0", "R" => "0" }
      end

      # Extract lane configurations from metrics
      if intersection.has_metric?("Lane Configurations")
        dir_map.each do |dir_code, position|
          %w[L T R].each do |movement|
            lane_key = "#{dir_code}#{movement}"
            begin
              config_value = intersection.get_value(lane_key, "Lane Configurations")
              if config_value && !config_value.strip.empty? && config_value != "0"
                config = parse_lane_config(config_value)
                if config
                  lane_config[position][movement] = config[:count].to_s
                  lane_config[position][movement] += ">" if config[:shared] == "right"
                  lane_config[position][movement] += "<" if config[:shared] == "left"
                end
              end
            rescue => e
              Rails.logger.debug("Lane config not found for #{lane_key}: #{e.message}")
            end
          end
        end
      end

      lane_config
    end

    def self.parse_lane_config(config_string)
      return nil if config_string.nil? || config_string.strip.empty? || config_string.strip == "0"

      clean_string = config_string.strip

      if clean_string.include?(">")
        count = clean_string.gsub(">", "").to_i
        { count: count, shared: "right" }
      elsif clean_string.include?("<")
        count = clean_string.gsub("<", "").to_i
        { count: count, shared: "left" }
      else
        { count: clean_string.to_i, shared: nil }
      end
    end

    def self.extract_movement_data(intersection, pm_intersection, dir_map)
      movements = {
        "left" => { "L" => {}, "T" => {}, "R" => {} },
        "right" => { "L" => {}, "T" => {}, "R" => {} },
        "top" => { "L" => {}, "T" => {}, "R" => {} },
        "bottom" => { "L" => {}, "T" => {}, "R" => {} }
      }

      volume_metric = "Traffic Volume (veh/h)"
      los_metric = "LnGrp LOS"

      dir_map.each do |dir_code, position|
        %w[L T R].each do |movement|
          lane_key = "#{dir_code}#{movement}"

          begin
            if intersection.has_metric?(volume_metric)
              am_vol = intersection.get_value(lane_key, volume_metric)
              movements[position][movement]["am_volume"] = am_vol&.to_i || 0
            end

            if intersection.has_metric?(los_metric)
              am_los = intersection.get_value(lane_key, los_metric)
              movements[position][movement]["am_los"] = am_los&.strip || "-"
            end
          rescue => e
            movements[position][movement]["am_volume"] = 0
            movements[position][movement]["am_los"] = "-"
            Rails.logger.debug("Error getting AM data for #{lane_key}: #{e.message}")
          end

          if pm_intersection
            begin
              if pm_intersection.has_metric?(volume_metric)
                pm_vol = pm_intersection.get_value(lane_key, volume_metric)
                movements[position][movement]["pm_volume"] = pm_vol&.to_i || 0
              end

              if pm_intersection.has_metric?(los_metric)
                pm_los = pm_intersection.get_value(lane_key, los_metric)
                movements[position][movement]["pm_los"] = pm_los&.strip || "-"
              end
            rescue => e
              movements[position][movement]["pm_volume"] = 0
              movements[position][movement]["pm_los"] = "-"
              Rails.logger.debug("Error getting PM data for #{lane_key}: #{e&.message}")
            end
          else
            movements[position][movement]["pm_volume"] = 0
            movements[position][movement]["pm_los"] = "-"
          end
        end
      end

      movements
    end

    def self.render_approach_data_vertical(position, data)
      html = "<div class=\"approach-vertical\">"

      movements_order = %w[R T L]

      # Calculate available lane groups
      lane_groups = []
      movements_order.each do |movement|
        if data[:lane_config][position][movement] != "0"
          lane_groups << movement
        end
      end

      if position == "bottom"
        lane_groups = lane_groups.reverse
      end

      lane_groups.each do |movement|
        movement_data = data[:movements][position][movement]
        los = "#{movement_data['am_los']}(#{movement_data['pm_los']})"
        volume = "#{movement_data['am_volume']}(#{movement_data['pm_volume']})"
        lane_config = data[:lane_config][position][movement]

        html += "<div class=\"lane-group-row direction-#{movement.downcase}\">"

        if position == "top"
          html += "<div class=\"volume\">#{volume}</div>"
          html += render_single_lane(position, movement, lane_config)
          html += "<div class=\"los\">#{los}</div>"
        else # bottom position
          html += "<div class=\"los\">#{los}</div>"
          html += render_single_lane(position, movement, lane_config)
          html += "<div class=\"volume\">#{volume}</div>"
        end

        html += "</div>"
      end

      html += "</div>"
      html
    end

    def self.render_approach_data_horizontal(position, data)
      html = "<div class=\"approach-horizontal\">"

      # Determine the correct order of movements based on position
      movements_order = position == "left" ? %w[L T R] : %w[R T L]

      # Create array of lane groups that exist
      lane_groups = []
      movements_order.each do |movement|
        if data[:lane_config][position][movement] != "0"
          lane_groups << movement
        end
      end

      lane_groups.each do |movement|
        movement_data = data[:movements][position][movement]
        los = "#{movement_data['am_los']}(#{movement_data['pm_los']})"
        volume = "#{movement_data['am_volume']}(#{movement_data['pm_volume']})"
        lane_config = data[:lane_config][position][movement]

        html += "<div class=\"lane-group-row direction-#{movement.downcase}\">"

        if position == "left"
          html += "<div class=\"volume\">#{volume}</div>"
          html += render_single_lane(position, movement, lane_config)
          html += "<div class=\"los\">#{los}</div>"
        else
          html += "<div class=\"los\">#{los}</div>"
          html += render_single_lane(position, movement, lane_config)
          html += "<div class=\"volume\">#{volume}</div>"
        end

        html += "</div>"
      end

      html += "</div>"
      html
    end

    # Generate SVG arrow for lane movements
    def self.generate_lane_arrow_svg(direction, movement)
      case [ direction, movement.downcase ]
      when %w[nb l]
        # Northbound left turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M15 25 L15 15 Q15 10 10 10 L5 10" stroke="black" stroke-width="2" fill="none" />
          <polygon points="5,7 5,13 1,10" fill="black" />
        </svg>
        SVG

      when %w[nb t]
        # Northbound through arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <line x1="15" y1="5" x2="15" y2="25" stroke="black" stroke-width="2" />
          <polygon points="12,5 18,5 15,1" fill="black" />
        </svg>
        SVG

      when %w[nb r]
        # Northbound right turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M15 25 L15 15 Q15 10 20 10 L25 10" stroke="black" stroke-width="2" fill="none" />
          <polygon points="25,7 25,13 29,10" fill="black" />
        </svg>
        SVG

      when %w[sb l]
        # Southbound left turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M15 5 L15 15 Q15 20 20 20 L25 20" stroke="black" stroke-width="2" fill="none" />
          <polygon points="25,17 25,23 29,20" fill="black" />
        </svg>
        SVG

      when %w[sb t]
        # Southbound through arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <line x1="15" y1="5" x2="15" y2="25" stroke="black" stroke-width="2" />
          <polygon points="12,25 18,25 15,29" fill="black" />
        </svg>
        SVG

      when %w[sb r]
        # Southbound right turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M15 5 L15 15 Q15 20 10 20 L5 20" stroke="black" stroke-width="2" fill="none" />
          <polygon points="5,17 5,23 1,20" fill="black" />
        </svg>
        SVG

      when %w[eb l]
        # Eastbound left turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M5 15 L15 15 Q20 15 20 10 L20 5" stroke="black" stroke-width="2" fill="none" />
          <polygon points="17,5 23,5 20,1" fill="black" />
        </svg>
        SVG

      when %w[eb t]
        # Eastbound through arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <line x1="5" y1="15" x2="25" y2="15" stroke="black" stroke-width="2" />
          <polygon points="25,12 25,18 29,15" fill="black" />
        </svg>
        SVG

      when %w[eb r]
        # Eastbound right turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M5 15 L15 15 Q20 15 20 20 L20 25" stroke="black" stroke-width="2" fill="none" />
          <polygon points="17,25 23,25 20,29" fill="black" />
        </svg>
        SVG

      when %w[wb l]
        # Westbound left turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M25 15 L15 15 Q10 15 10 20 L10 25" stroke="black" stroke-width="2" fill="none" />
          <polygon points="7,25 13,25 10,29" fill="black" />
        </svg>
        SVG

      when %w[wb t]
        # Westbound through arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <line x1="5" y1="15" x2="25" y2="15" stroke="black" stroke-width="2" />
          <polygon points="5,12 5,18 1,15" fill="black" />
        </svg>
        SVG

      when %w[wb r]
        # Westbound right turn arrow
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet">
          <path d="M25 15 L15 15 Q10 15 10 10 L10 5" stroke="black" stroke-width="2" fill="none" />
          <polygon points="7,5 13,5 10,1" fill="black" />
        </svg>
        SVG

      else
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg" preserveAspectRatio="xMidYMid meet"></svg>
        SVG
      end
    end

    # Generate SVG for shared lanes
    def self.generate_shared_lane_svg(direction, primary_movement, shared_direction)
      primary_svg = generate_lane_arrow_svg(direction, primary_movement)

      case [ direction, primary_movement.downcase, shared_direction ]
      when %w[nb t r]
        # Northbound through+right
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg shared-lane-svg" preserveAspectRatio="xMidYMid meet">
          <!-- Through arrow -->
          <line x1="15" y1="5" x2="15" y2="25" stroke="black" stroke-width="2" />
          <polygon points="12,5 18,5 15,1" fill="black" />
        #{'  '}
          <!-- Right turn arrow-->
          <path d="M15 20 Q15 15 20 10 L25 10" stroke="black" stroke-width="2" fill="none"" />
          <polygon points="25,7 25,13 29,10" fill="black" />
        </svg>
        SVG

      when %w[sb t r]
        # Southbound through+right
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg shared-lane-svg" preserveAspectRatio="xMidYMid meet">
          <!-- Through arrow -->
          <line x1="15" y1="5" x2="15" y2="25" stroke="black" stroke-width="2" />
          <polygon points="12,25 18,25 15,29" fill="black" />
        #{'  '}
          <!-- Right turn arrow-->
          <path d="M15 10 Q15 15 10 20 L5 20" stroke="black" stroke-width="2" fill="none"" />
          <polygon points="5,17 5,23 1,20" fill="black" />
        </svg>
        SVG

      when %w[eb t r]
        # Eastbound through+right
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg shared-lane-svg" preserveAspectRatio="xMidYMid meet">
          <!-- Through arrow -->
          <line x1="5" y1="15" x2="25" y2="15" stroke="black" stroke-width="2" />
          <polygon points="25,12 25,18 29,15" fill="black" />
        #{'  '}
          <!-- Right turn arrow-->
          <path d="M15 15 Q20 15 20 20 L20 25" stroke="black" stroke-width="2" fill="none"" />
          <polygon points="17,25 23,25 20,29" fill="black" />
        </svg>
        SVG

      when %w[wb t r]
        # Westbound through+right
        <<-SVG
        <svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg" class="lane-arrow-svg shared-lane-svg" preserveAspectRatio="xMidYMid meet">
          <!-- Through arrow -->
          <line x1="5" y1="15" x2="25" y2="15" stroke="black" stroke-width="2" />
          <polygon points="5,12 5,18 1,15" fill="black" />
        #{'  '}
          <!-- Right turn arrow-->
          <path d="M15 15 Q10 15 10 10 L10 5" stroke="black" stroke-width="2" fill="none"" />
          <polygon points="7,5 13,5 10,1" fill="black" />
        </svg>
        SVG
      else
        primary_svg
      end
    end

    def self.render_single_lane(position, movement, lane_config)
      direction_mapping = {
        "top" => "sb",
        "bottom" => "nb",
        "left" => "eb",
        "right" => "wb"
      }

      direction = direction_mapping[position]
      html = "<div class=\"lane-group\">"

      if lane_config != "0"
        lane_count = lane_config.gsub(/[<>]/, "").to_i
        shared_right = lane_config.include?(">")
        shared_left = lane_config.include?("<")

        lane_count.times do |i|
          lane_class = "lane-line #{direction}-#{movement.downcase}"

          if lane_count > 1
            lane_class += " lane-#{i+1}-of-#{lane_count}"
          end

          if (shared_right && i == lane_count - 1) || (shared_left && i == 0)
            if shared_right
              lane_class += " shared-right"
            elsif shared_left
              lane_class += " shared-left"
            end
          end

          html += "<div class=\"#{lane_class}\">"

          # Add SVG arrow based on lane type
          html += "<div class=\"lane-arrow-container\">"

          if position == "top" || position == "left"
            if shared_right && i == lane_count - 1
              html += generate_shared_lane_svg(direction, movement.downcase, "r")
            elsif shared_left && i == 0
              html += generate_shared_lane_svg(direction, movement.downcase, "l")
            else
              html += generate_lane_arrow_svg(direction, movement.downcase)
            end
            html += "</div>"
          end

          if position == "bottom" || position == "right"
            if shared_left && i == lane_count - 1
              html += generate_shared_lane_svg(direction, movement.downcase, "l")
            elsif shared_right && i == 0
              html += generate_shared_lane_svg(direction, movement.downcase, "r")
            else
              html += generate_lane_arrow_svg(direction, movement.downcase)
            end
            html += "</div>"
          end

          html += "</div>"
        end
      end

      html += "</div>"
      html
    end

    def self.format_intersection_name(name)
      if name.include?(":")
        index_and_name = name.split(":")
        "#{index_and_name[0].strip}: #{index_and_name[1].strip}"
      else
        name
      end
    end
  end
end
