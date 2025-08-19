require 'rails_helper'

RSpec.describe SynchroParser::Report do
  let(:format1_file) { File.read(Rails.root.join("spec", "fixtures", "New_Format.txt")) }
  let(:format2_file) { File.read(Rails.root.join("spec", "fixtures", "New_Format_2.txt")) }

  # Test configurations that alternate the file formats between AM and PM
  let(:am_format2_pm_format1) { described_class.new(format2_file, format1_file) }
  let(:am_format1_pm_format2) { described_class.new(format1_file, format2_file) }

  describe "parsing an AM file" do
    context "with Format 2 file" do
      it "extracts intersections" do
        report = described_class.new(format2_file)
        expect(report.intersections).not_to be_empty

        # The key for an AM file intersection should have " AM" appended
        intersection = report.intersections["Alameda Blvd. & Guadalupe Tr. AM"]
        expect(intersection).to be_present
        expect(intersection.name).to eq("Alameda Blvd. & Guadalupe Tr.")

        # Test that a specific metric exists
        lane_config = intersection.metrics["Lane Configurations"]
        expect(lane_config).to be_present
        expect(lane_config["EBL"]).to eq("1")
      end
    end

    context "with Format 1 file" do
      it "extracts intersections" do
        report = described_class.new(format1_file)
        expect(report.intersections).not_to be_empty

        # The key for an AM file intersection should have " AM" appended
        intersection = report.intersections["Broadmoor Blvd & Paseo Del Volcan AM"]
        expect(intersection).to be_present
        expect(intersection.name).to eq("Broadmoor Blvd & Paseo Del Volcan")

        # Test that a specific metric exists
        lane_config = intersection.metrics["Lane Configurations"]
        expect(lane_config).to be_present
        expect(lane_config["EBL"]).to eq("1")
      end
    end
  end

  describe "comparing AM and PM reports" do
    context "when both files have the same format" do
      it "detects no missing intersections for Format 2 files" do
        report = described_class.new(format2_file, format2_file)
        expect(report.errors).to be_empty
      end

      it "detects no missing intersections for Format 1 files" do
        report = described_class.new(format1_file, format1_file)
        expect(report.errors).to be_empty
      end
    end

    context "when files have different formats" do
      it "identifies differences between Format 2 (AM) and Format 1 (PM)" do
        expect(am_format2_pm_format1.errors).not_to be_empty
      end

      it "identifies differences between Format 1 (AM) and Format 2 (PM)" do
        expect(am_format1_pm_format2.errors).not_to be_empty
      end
    end
  end

  describe "when file format is invalid" do
    it "reports an error" do
      invalid_file = "This is not a Synchro export file"
      report = described_class.new(invalid_file)
      expect(report.errors).to include("File does not appear to be a valid Synchro export.")
    end
  end

  describe "#get_values" do
    it "returns an array of hashes with the intersection name and metric value for Format 2 AM file" do
      report = described_class.new(format2_file)
      result = report.get_values("EBL", "Lane Configurations", "AM")
      expect(result).to be_an(Array)
      result.each do |hash|
        expect(hash).to include(:name, :value)
      end
      expect(result).to include({ name: "Alameda Blvd. & Guadalupe Tr.", value: "1" })
    end

    it "returns an array of hashes with the intersection name and metric value for Format 1 AM file" do
      report = described_class.new(format1_file)
      result = report.get_values("EBL", "Lane Configurations", "AM")
      expect(result).to be_an(Array)
      result.each do |hash|
        expect(hash).to include(:name, :value)
      end
      expect(result).to include({ name: "Broadmoor Blvd & Paseo Del Volcan", value: "1" })
    end

    it "returns an array of hashes with the intersection name and metric value for Format 2 PM file" do
      report = described_class.new(nil, format2_file)
      result = report.get_values("EBL", "Lane Configurations", "PM")
      expect(result).to be_an(Array)
      result.each do |hash|
        expect(hash).to include(:name, :value)
      end
      expect(result).to include({ name: "Alameda Blvd. & Guadalupe Tr.", value: "1" })
    end

    it "returns an array of hashes with the intersection name and metric value for Format 1 PM file" do
      report = described_class.new(nil, format1_file)
      result = report.get_values("EBL", "Lane Configurations", "PM")
      expect(result).to be_an(Array)
      result.each do |hash|
        expect(hash).to include(:name, :value)
      end
      expect(result).to include({ name: "Broadmoor Blvd & Paseo Del Volcan", value: "1" })
    end
  end

  describe "#get_value" do
    context "when retrieving values from Format 1 file" do
      let(:report) { described_class.new(format1_file) }

      it "retrieves a specific metric value for a known intersection and direction" do
        # Test getting Lane Configuration value for EBL direction at Broadmoor & Paseo Del Volcan
        value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Lane Configurations", "AM")
        expect(value).to eq("1")

        # Test getting Traffic Volume value for NBR direction
        value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "NBR", "Traffic Volume (veh/h)", "AM")
        expect(value).to eq("122")
      end

      it "raises an error for a non-existent metric" do
        expect {
          report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Non-existent Metric", "AM")
        }.to raise_error(SynchroParser::ParseError, /Metric 'Non-existent Metric' not found/)
      end

      it "raises an error for a non-existent intersection" do
        expect {
          report.get_value("Non-existent Intersection", "EBL", "Lane Configurations", "AM")
        }.to raise_error(SynchroParser::ParseError, /Intersection 'Non-existent Intersection' not found/)
      end
    end

    context "when retrieving values from Format 2 file" do
      let(:report) { described_class.new(format2_file) }

      it "retrieves a specific metric value for a known intersection and direction" do
        # Test getting Lane Configuration value for EBL direction at Alameda & Guadalupe
        value = report.get_value("Alameda Blvd. & Guadalupe Tr.", "EBL", "Lane Configurations", "AM")
        expect(value).to eq("1")

        # Test getting Traffic Volume value for WBT direction
        value = report.get_value("Alameda Blvd. & Guadalupe Tr.", "WBT", "Traffic Volume (veh/h)", "AM")
        expect(value).to eq("708")
      end
    end

    context "when retrieving values from PM files" do
      let(:report) { described_class.new(nil, format1_file) }

      it "retrieves a specific metric value for a known intersection and direction" do
        value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Lane Configurations", "PM")
        expect(value).to eq("1")
      end

      it "raises an error for a non-existent metric in PM file" do
        expect {
          report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Non-existent Metric", "PM")
        }.to raise_error(SynchroParser::ParseError, /Metric 'Non-existent Metric' not found/)
      end
    end

    context "with invalid file type" do
      let(:report) { described_class.new(format1_file, format2_file) }

      it "raises an error for an invalid file type" do
        expect {
          report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Lane Configurations", "invalid")
        }.to raise_error(SynchroParser::ParseError, /Invalid file type: invalid/)
      end
    end

    context "when both AM and PM files are provided" do
      let(:report) { described_class.new(format1_file, format2_file) }

      it "retrieves values from the correct file based on specified file type" do
        # From AM file (format1)
        am_value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "NBR", "Traffic Volume (veh/h)", "AM")
        expect(am_value).to eq("122")

        # From PM file (format2) - different intersection
        pm_value = report.get_value("Alameda Blvd. & Guadalupe Tr.", "SBL", "Traffic Volume (veh/h)", "PM")
        expect(pm_value).to eq("16")
      end
    end

    context "when files are updated during the session" do
      let(:report) { described_class.new }

      it "retrieves values from newly added files" do
        # Start with empty report
        expect(report.intersections).to be_empty

        # Add AM file
        report.add_am_file(format1_file)
        am_value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Lane Configurations", "AM")
        expect(am_value).to eq("1")

        # Add PM file
        report.add_pm_file(format2_file)
        pm_value = report.get_value("Alameda Blvd. & Guadalupe Tr.", "EBL", "Lane Configurations", "PM")
        expect(pm_value).to eq("1")
      end
    end

    context "when handling edge cases" do
      let(:report) { described_class.new(format1_file) }

      it "correctly handles whitespace in direction values" do
        # The parser strips whitespace from values, verify this behavior works
        value = report.get_value("Broadmoor Blvd & Paseo Del Volcan", "EBL", "Lane Configurations", "AM")
        expect(value).not_to include(" ")
      end
    end
  end

  describe "#add_am_file" do
    context "when no AM file is initially provided" do
      it "parses and adds intersections from Format 2 AM file" do
        # Start with a report that only has a PM file
        report = described_class.new(nil, format2_file)
        expect(report.am_file).to be_nil
        expect(report.intersections.keys.none? { |key| key.end_with?("AM") }).to eq(true)

        # Add the AM file
        report.add_am_file(format2_file)
        expect(report.am_file).to eq(format2_file)
        # The merged intersections should now include keys ending with " AM"
        expect(report.intersections.keys.any? { |key| key.end_with?("AM") }).to eq(true)
      end

      it "parses and adds intersections from Format 1 AM file" do
        # Start with a report that only has a PM file
        report = described_class.new(nil, format1_file)
        expect(report.am_file).to be_nil
        expect(report.intersections.keys.none? { |key| key.end_with?("AM") }).to eq(true)

        # Add the AM file
        report.add_am_file(format1_file)
        expect(report.am_file).to eq(format1_file)
        # The merged intersections should now include keys ending with " AM"
        expect(report.intersections.keys.any? { |key| key.end_with?("AM") }).to eq(true)
      end
    end

    context "when both files are present and intersections mismatch" do
      it "updates errors when adding Format 1 file as AM to report with Format 2 files" do
        # Start with a report that has both files and no errors
        report = described_class.new(format2_file, format2_file)
        expect(report.errors).to be_empty

        # Replace the AM file with one that has mismatched intersections
        report.add_am_file(format1_file)
        # Expect an error indicating missing intersections in the AM file
        expect(report.errors.join).to include("Intersections missing in AM file")
      end

      it "updates errors when adding Format 2 file as AM to report with Format 1 files" do
        # Start with a report that has both files and no errors
        report = described_class.new(format1_file, format1_file)
        expect(report.errors).to be_empty

        # Replace the AM file with one that has mismatched intersections
        report.add_am_file(format2_file)
        # Expect an error indicating missing intersections in the AM file
        expect(report.errors.join).to include("Intersections missing in AM file")
      end
    end
  end

  describe "#add_pm_file" do
    context "when no PM file is initially provided" do
      it "parses and adds intersections from Format 2 PM file" do
        # Start with a report that only has an AM file
        report = described_class.new(format2_file, nil)
        expect(report.pm_file).to be_nil
        expect(report.intersections.keys.none? { |key| key.end_with?("PM") }).to eq(true)

        # Add the PM file
        report.add_pm_file(format2_file)
        expect(report.pm_file).to eq(format2_file)
        # The merged intersections should now include keys ending with " PM"
        expect(report.intersections.keys.any? { |key| key.end_with?("PM") }).to eq(true)
      end

      it "parses and adds intersections from Format 1 PM file" do
        # Start with a report that only has an AM file
        report = described_class.new(format1_file, nil)
        expect(report.pm_file).to be_nil
        expect(report.intersections.keys.none? { |key| key.end_with?("PM") }).to eq(true)

        # Add the PM file
        report.add_pm_file(format1_file)
        expect(report.pm_file).to eq(format1_file)
        # The merged intersections should now include keys ending with " PM"
        expect(report.intersections.keys.any? { |key| key.end_with?("PM") }).to eq(true)
      end
    end

    context "when both files are present and intersections mismatch" do
      it "updates errors when adding Format 1 file as PM to report with Format 2 files" do
        # Start with a report that has both files and no errors
        report = described_class.new(format2_file, format2_file)
        expect(report.errors).to be_empty

        # Replace the PM file with one that has mismatched intersections
        report.add_pm_file(format1_file)
        # Expect an error indicating missing intersections in the PM file
        expect(report.errors.join).to include("Intersections missing in PM file")
      end

      it "updates errors when adding Format 2 file as PM to report with Format 1 files" do
        # Start with a report that has both files and no errors
        report = described_class.new(format1_file, format1_file)
        expect(report.errors).to be_empty

        # Replace the PM file with one that has mismatched intersections
        report.add_pm_file(format2_file)
        # Expect an error indicating missing intersections in the PM file
        expect(report.errors.join).to include("Intersections missing in PM file")
      end
    end
  end

  describe "Control Delay and LOS" do
    context "with Format 2 file" do
      it "correctly extracts control delay and LOS values from intersections" do
        report = described_class.new(format2_file)

        intersection = report.intersections["Alameda Blvd. & Guadalupe Tr. AM"]
        expect(intersection).to be_present
        expect(intersection.control_delay).to eq("2.2")
        expect(intersection.los).to eq("A")

        intersection = report.intersections["Thomas Ln./Rio Grand Blvd. (North) & Alameda Blvd. AM"]
        expect(intersection).to be_present
        expect(intersection.control_delay).to eq("3.5")
        expect(intersection.los).to eq("A")

        intersection = report.intersections["Rio Grande Blvd. (South) & Alameda Blvd. AM"]
        expect(intersection).to be_present
        expect(intersection.control_delay).to eq("13.0")
        expect(intersection.los).to eq("B")
      end

      it "handles TWSC intersections" do
        report = described_class.new(format2_file)

        # Two-Way Stop Controlled (TWSC) intersections may have different or no summary format
        intersection = report.intersections["Alameda Blvd. & Driveway A AM"]
        expect(intersection).to be_present
        # For TWSC intersections, we may have different expectations
        # In the sample file, this intersection has Int Delay of 0
        expect(intersection.control_delay).to eq(0.0)
      end
    end

    context "with Format 1 file" do
      it "correctly extracts control delay and LOS values" do
        report = described_class.new(format1_file)

        # Test a sample intersection from Format 1
        # Note: Since Format 1 file content isn't shown in full, we're making assumptions
        # about what intersections might exist. Adjust as needed.
        intersection = report.intersections["Broadmoor Blvd & Paseo Del Volcan AM"]
        expect(intersection).to be_present
        expect(intersection.control_delay).not_to be_nil
        expect(intersection.los).not_to be_nil
      end
    end
  end

  describe "Adding and retrieving values through the Intersection class" do
    it "allows setting and retrieving LOS and control delay values" do
      intersection = SynchroParser::Intersection.new(
        name: "Test Intersection",
        date: "01/01/2025",
        file_type: "AM"
      )

      # Initially values should be nil
      expect(intersection.los).to be_nil
      expect(intersection.control_delay).to be_nil

      # Set values
      intersection.add_los("C")
      intersection.add_control_delay("22.5")

      # Verify values were set
      expect(intersection.los).to eq("C")
      expect(intersection.control_delay).to eq("22.5")
    end
  end

  describe "Helper methods for getting values" do
    context "when getting LOS values" do
      it "retrieves LOS values for all intersections in a file type" do
        # Create a new helper method in the Report class
        class SynchroParser::Report
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
              raise ParseError, "Invalid file type: #{file_type}"
            end

            results
          end
        end

        report = described_class.new(format2_file)
        los_values = report.get_los_values("AM")

        expect(los_values).to be_an(Array)
        expect(los_values).not_to be_empty

        # Each item should have name and LOS value
        los_values.each do |item|
          expect(item).to include(:name, :los)
        end

        # Verify sample values
        expect(los_values).to include(
                                { name: "Alameda Blvd. & Guadalupe Tr.", los: "A" }
                              )
      end
    end

    context "when getting control delay values" do
      it "retrieves control delay values for all intersections in a file type" do
        # Create a new helper method in the Report class
        class SynchroParser::Report
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
              raise ParseError, "Invalid file type: #{file_type}"
            end

            results
          end
        end

        report = described_class.new(format2_file)
        delay_values = report.get_control_delay_values("AM")

        expect(delay_values).to be_an(Array)
        expect(delay_values).not_to be_empty

        # Each item should have name and control delay value
        delay_values.each do |item|
          expect(item).to include(:name, :control_delay)
        end

        # Verify sample values
        expect(delay_values).to include(
                                  { name: "Alameda Blvd. & Guadalupe Tr.", control_delay: "2.2" }
                                )
      end
    end
  end
end
