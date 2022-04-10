RSpec.describe Export::Ara do
  describe "a whole export" do
    let(:context) do
      Chouette.create do
        organisation :owner, features: %w{export_ara_stop_visits}
        workbench organisation: :owner do
          time_table :default
          vehicle_journey time_tables: [:default]
        end
      end
    end

    subject(:export) do
      Export::Ara.create! workbench: context.workbench,
                          workgroup: context.workgroup,
                          referential: context.referential,
                          name: "Test",
                          creator: "test"
    end

    before do
      export.export
      export.reload
    end

    it { is_expected.to be_successful }

    describe "file" do
      # TODO Use Ara::File to read the file
      subject { export.file.read.split("\n") }
      it { is_expected.to have_attributes(size: 48) }
    end
  end

  describe "Stops export" do
    context "when two Stop Areas are exported" do
      let(:context) do
        Chouette.create { stop_area(:first) ; stop_area(:other) }
      end

      let(:stop_area) { context.stop_area(:first ) }
      let(:other_stop_area) { context.stop_area(:other) }

      let(:scope) { double stop_areas: context.stop_area_referential.stop_areas, codes: context.workgroup.codes }
      let(:target) { [] }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      let(:part) { Export::Ara::Stops.new export_scope: scope, target: target }

      describe "the Ara File target" do
        subject { part.export! ; target }
        it { is_expected.to match_array([an_instance_of(Ara::StopArea)]*2) }

        context "when one of the Stop Area has a registration number 'dummy'" do
          before { stop_area.update registration_number: "dummy" }
          it { is_expected.to include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when all Stop Area has a registration number 'dummy'" do
          before { scope.stop_areas.update_all registration_number: "dummy" }
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when one of the Stop Area has a code 'test': 'dummy" do
          before { stop_area.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Stop Areas has a code 'test': 'dummy" do
          before do
            scope.stop_areas.each do |stop_area|
              stop_area.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "Lines export" do
    context "when two Lines are exported" do
      let(:context) do
        Chouette.create { line(:first) ; line(:other) }
      end

      let(:line) { context.line(:first ) }
      let(:other_line) { context.line(:other) }

      let(:scope) { double lines: context.line_referential.lines, codes: context.workgroup.codes }
      let(:target) { [] }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      let(:part) { Export::Ara::Lines.new export_scope: scope, target: target }

      describe "the Ara File target" do
        subject { part.export! ; target }
        it { is_expected.to match_array([an_instance_of(Ara::Line)]*2) }

        context "when one of the Line has a registration number 'dummy'" do
          before { line.update registration_number: "dummy" }
          it { is_expected.to include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when all Line has a registration number 'dummy'" do
          before { scope.lines.update_all registration_number: "dummy" }
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when one of the Line has a code 'test': 'dummy" do
          before { line.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Lines has a code 'test': 'dummy" do
          before do
            scope.lines.each do |line|
              line.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "VehicleJourneys export" do
    context "when two Vehicle Journeys are exported" do
      let(:context) do
        Chouette.create { vehicle_journey(:first) ; vehicle_journey(:other) }
      end

      let(:referential) { context.referential }
      before { referential.switch }

      let(:vehicle_journey) { context.vehicle_journey(:first ) }
      let(:other_vehicle_journey) { context.vehicle_journey(:other) }

      let(:scope) { referential }
      let(:target) { [] }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      let(:part) { Export::Ara::VehicleJourneys.new export_scope: scope, target: target }

      describe "the Ara File target" do
        subject { part.export! ; target }
        it { is_expected.to match_array([an_instance_of(Ara::VehicleJourney)]*2) }

        context "when one of the Vehicle Journey has a code 'test': 'dummy" do
          before { vehicle_journey.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Vehicle Journeys has a code 'test': 'dummy" do
          before do
            scope.vehicle_journeys.each do |vehicle_journey|
              vehicle_journey.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "StopVisit export" do
    context "when Stop Visits are exported" do
      let(:context) do
        Chouette.create { vehicle_journey }
      end
      let(:target) { [] }
      let(:referential) { context.referential }
      let(:vehicle_journey) { context.vehicle_journey }

      let(:part) { Export::Ara::StopVisits.new export_scope: referential, target: target }

      before { referential.switch }

      describe "the Ara File target" do
        subject { part.export! ; target }

        let(:at_stops_count) { vehicle_journey.vehicle_journey_at_stops.count }

        it { is_expected.to match_array([an_instance_of(Ara::StopVisit)] * at_stops_count) }

        describe Export::Ara::StopVisits::Decorator do

          let(:vehicle_journey_at_stop) {vehicle_journey.vehicle_journey_at_stops.first }
          let(:stop_visit_decorator) { Export::Ara::StopVisits::Decorator.new vehicle_journey_at_stop }

          let(:experted_attributes) do
            an_object_having_attributes({
              schedules: [{
                "Kind" => "expected",
                "ArrivalTime" => "2000-01-01T19:01:00+0000",
                "DepartureTime" => "2000-01-01T15:01:00+0000"
              }],
              passage_order: "0"
            })
          end

          before do
            vehicle_journey_at_stop.update(
              arrival_time: "2000-01-01T19:01:00+000".to_datetime,
              departure_time: "2000-01-01T15:01:00+0000".to_datetime
            )
            vehicle_journey_at_stop.stop_point.update position: 0
          end

          it "should create stop_visits with the correct attributes" do
            expect([stop_visit_decorator.ara_model]).to include(experted_attributes)
          end
        end
      end
    end
  end

end
