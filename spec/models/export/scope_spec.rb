RSpec.describe Export::Scope, use_chouette_factory: true do

  describe "Base" do

    describe "shape_referential" do

      it "uses Workgroup shape referential" do
        referential = double(workgroup: double(shape_referential: double))

        expect(Export::Scope::Base.new(referential).shape_referential).
          to be(referential.workgroup.shape_referential)
      end

    end

    describe "stop_areas" do

      it "uses workbench stop areas" do
        referential = double(workbench: double(stop_areas: double))

        expect(Export::Scope::Base.new(referential).stop_areas).
          to be(referential.workbench.stop_areas)
      end

      context "without workbench" do
        it "uses stop areas from stop area referential" do
          referential = double(workbench: nil,
                               stop_area_referential: double(stop_areas: double))

          expect(Export::Scope::Base.new(referential).stop_areas).
            to be(referential.stop_area_referential.stop_areas)
        end
      end

    end

    describe "lines" do

      it "uses workbench lines" do
        referential = double(workbench: double(lines: double))

        expect(Export::Scope::Base.new(referential).lines).
          to be(referential.workbench.lines)
      end

      context "without workbench" do
        it "uses lines from line referential" do
          referential = double(workbench: nil,
                               line_referential: double(lines: double))

          expect(Export::Scope::Base.new(referential).lines).
            to be(referential.line_referential.lines)
        end
      end

    end

    describe "metadatas" do

      let(:referential) { double metadatas: double("referential metadatas") }
      let(:scope) { Export::Scope::Base.new(referential) }

      subject { scope.metadatas }

      it { is_expected.to eq(referential.metadatas) }

    end

    describe "organisations" do

      let(:context) do
        Chouette.create do
          referential
        end
      end

      let(:referential) { context.referential }
      let(:scope) { Export::Scope::Base.new(referential) }

      subject { scope.organisations }

      context 'no metadatas are related to organisations through referential_source' do
        it { is_expected.to be_empty }
      end

      context 'some metadatas are related to organisations through referential_source' do
        before do
          # Use the referential .. as its own source for the test
          referential.metadatas.update_all referential_source_id: referential.id
        end
        let(:organisation) { referential.organisation }

        it "returns related organisations" do
          is_expected.to contain_exactly(organisation)
        end
      end

    end

  end

  describe "DateRange" do

    let!(:context) do
      Chouette.create do
        line :first
        line :second
        line :third

        stop_area :specific_stop

        workbench do
          shape :shape_in_scope1
          shape :shape_in_scope2
          shape

          referential lines: [:first, :second, :third] do
            time_table :default

            route :in_scope1, line: :first do
              journey_pattern :in_scope1, shape: :shape_in_scope1 do
                vehicle_journey :in_scope1, time_tables: [:default]
              end
              journey_pattern :in_scope2, shape: :shape_in_scope1 do
                vehicle_journey :in_scope2, time_tables: [:default]
              end
            end
            route :in_scope2, line: :second do
              journey_pattern :in_scope3, shape: :shape_in_scope2 do
                vehicle_journey :in_scope3, time_tables: [:default]
              end
              vehicle_journey # no timetable
            end
            route
          end
        end
      end
    end

    # around(:each) lets models in database after spec (?!)
    before do
      context.referential.switch
    end

    let(:date_range) { context.time_table(:default).date_range }
    let(:scope) { Export::Scope::DateRange.new context.referential, date_range }

    let(:vehicle_journeys_in_scope) do
      [:in_scope1, :in_scope2, :in_scope3].map { |n| context.vehicle_journey(n) }
    end

    let(:routes_in_scope) { [:in_scope1, :in_scope2].map { |n| context.route(n) } }
    let(:journey_patterns_in_scope) { [:in_scope1, :in_scope2, :in_scope3].map { |n| context.journey_pattern(n) } }

    describe "stop_areas" do

      let(:stop_areas_in_scope) { routes_in_scope.map(&:stop_areas).flatten.uniq }

      it "select stop areas associated with routes" do
        expect(scope.stop_areas).to match_array(stop_areas_in_scope)
      end

      it "doesn't provide a Stop Area twice" do
        expect(scope.stop_areas).to be_uniq
      end

      context "when a VehicleJourneyAtStop has a specific Stop" do

        let(:vehicle_journey_at_stop) do
          vehicle_journeys_in_scope.sample.vehicle_journey_at_stops.sample
        end
        let(:specific_stop) { context.stop_area(:specific_stop) }

        before do
          vehicle_journey_at_stop.update stop_area: specific_stop
        end

        it "select specific stops" do
          expect(scope.stop_areas).to include(specific_stop)
        end

      end

    end

    describe "stop_points" do

      let(:stop_points_in_scope) do
        routes_in_scope.map(&:stop_points).flatten.uniq
      end

      it "select stop points associated with routes" do
        expect(scope.stop_points).to match_array(stop_points_in_scope)
      end

      it "doesn't provide a Stop Point twice" do
        expect(scope.stop_points).to be_uniq
      end

    end

    describe "routes" do

      it "select routes associated with vehicle journeys in scope" do
        expect(scope.routes).to match_array(routes_in_scope)
      end

      it "doesn't provide a Route twice" do
        expect(scope.routes).to be_uniq
      end

    end

    describe "journey_patterns" do

      it "select journey patterns associated with vehicle journeys in scope" do
        expect(scope.journey_patterns).to match_array(journey_patterns_in_scope)
      end

      it "doesn't provide a Journey Pattern twice" do
        expect(scope.journey_patterns).to be_uniq
      end

    end

    describe "vehicle_journeys" do

      it "select vehicle journeys with a time table in the date range" do
        expect(scope.vehicle_journeys).to eq(vehicle_journeys_in_scope)
      end

    end

    describe "lines" do

      let(:lines_with_vehicle_journeys) { [context.line(:first), context.line(:second)] }

      it "select lines associated to vehicle journeys in date range" do
        expect(scope.lines).to eq(lines_with_vehicle_journeys)
      end

      it "doesn't provide a line twice" do
        expect(scope.lines).to be_uniq
      end

    end

    describe "vehicle_journeys_at_stops" do

      let(:vehicle_journey_at_stops_in_scope) do
        vehicle_journeys_in_scope.map(&:vehicle_journey_at_stops).flatten
      end

      it "select all VehicleJourneyAtStops associated to vehicle journeys in date range" do
        expect(scope.vehicle_journey_at_stops).to match_array(vehicle_journey_at_stops_in_scope)
      end

      it "doesn't provide a VehicleJourneyAtStop twice" do
        expect(scope.vehicle_journey_at_stops).to be_uniq
      end

    end

    describe "journey_patterns" do

      it "select shapes associated with journey patterns in scope" do
        shapes_in_scope = journey_patterns_in_scope.map(&:shape).uniq
        expect(scope.shapes).to match_array(shapes_in_scope)
      end

      it "doesn't provide a Shape twice" do
        expect(scope.shapes).to be_uniq
      end

    end

    describe "#metadatas" do

      let(:lines) { [ context.line(:first) ] }

      let(:period_before_daterange) { (date_range.begin - 100)..(date_range.begin - 10) }
      let(:period_after_daterange) { (date_range.end + 10)..(date_range.end + 100) }

      let(:metadata_out_of_scope) do
        referential.metadatas.create! lines: lines, periodes: [period_before_daterange, period_after_daterange]
      end

      subject { scope.metadatas }

      it "returns only referential metadatas in scope date range" do
        is_expected.to_not include(metadata_out_of_scope)
      end

    end

  end

end
