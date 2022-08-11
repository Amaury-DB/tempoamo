RSpec.describe Export::Ara do
  describe 'a whole export' do
    let(:context) do
      Chouette.create do
        organisation :owner, features: %w[export_ara_stop_visits]
        workbench organisation: :owner do
          time_table :default
          vehicle_journey time_tables: [:default]
        end
      end
    end

    describe 'export with include_stop_visits sets to true' do
      subject(:export) do
        Export::Ara.create! workbench: context.workbench,
                            workgroup: context.workgroup,
                            referential: context.referential,
                            name: 'Test',
                            creator: 'test',
                            options: {include_stop_visits: true}

      end

      before do
        export.export
        export.reload
      end

      it { is_expected.to be_successful }

      describe 'file' do
        subject(:source) { Ara::File::Source.new(export.file.path) }
        describe 'stop_visits count ' do
          subject { source.stop_visits.to_a.size }
          it { is_expected.to eq(18) }
        end
        describe 'lines count' do
          subject { source.lines.to_a.size }
          it { is_expected.to eq(6) }
        end
        describe 'vehicle_journeys count' do
          subject { source.vehicle_journeys.to_a.size }
          it { is_expected.to eq(6) }
        end
        describe 'operators count' do
          subject { source.operators.to_a.size }
          it { is_expected.to eq(0) }
        end
      end
    end

    describe 'export with include_stop_visits sets to false' do
      subject(:export) do
        Export::Ara.create! workbench: context.workbench,
                            workgroup: context.workgroup,
                            referential: context.referential,
                            name: 'Test',
                            creator: 'test',
                            options: {include_stop_visits: false}

      end

      before do
        export.export
        export.reload
      end

      it { is_expected.to be_successful }

      describe 'file' do
        subject(:source) { Ara::File::Source.new(export.file.path) }
        describe 'stop_visits count ' do
          subject { source.stop_visits.to_a.size }
          it { is_expected.to eq(0) }
        end
        describe 'lines count' do
          subject { source.lines.to_a.size }
          it { is_expected.to eq(6) }
        end
        describe 'vehicle_journeys count' do
          subject { source.vehicle_journeys.to_a.size }
          it { is_expected.to eq(6) }
        end
        describe 'operators count' do
          subject { source.operators.to_a.size }
          it { is_expected.to eq(0) }
        end
      end
    end
  end

  describe 'Stops export' do
    describe Export::Ara::Stops::Decorator do
      subject(:decorator) { described_class.new(stop_area) }
      let(:stop_area) { Chouette::StopArea.new }

      describe '#parent_uuid' do
        subject { decorator.parent_uuid }

        context "when StopArea parent isn't defined" do
          before { stop_area.parent = nil }

          it { is_expected.to be_nil }
        end

        context "when StopArea parent objectid is 'test:StopArea:uuid'" do
          before { stop_area.parent = Chouette::StopArea.new(objectid: 'test:StopArea:uuid') }

          it { is_expected.to eq('uuid') }
        end
      end

      describe '#referent_uuid' do
        subject { decorator.referent_uuid }

        context "when StopArea parent isn't defined" do
          before { stop_area.referent = nil }

          it { is_expected.to be_nil }
        end

        context "when StopArea referent objectid is 'test:StopArea:uuid'" do
          before { stop_area.referent = Chouette::StopArea.new(objectid: 'test:StopArea:uuid') }

          it { is_expected.to eq('uuid') }
        end
      end

      describe '#line_uuids' do
        subject { decorator.line_uuids }

        context 'when StopArea is not associated to a Line' do
          it { is_expected.to be_empty }
        end

        context "when StopArea is associated to a Line identified by 'chouette:Line:uuid:LOC'" do
          before { allow(stop_area).to receive(:lines) { [Chouette::Line.new(objectid: 'chouette:Line:uuid:LOC')] } }
          it { is_expected.to contain_exactly('uuid') }
        end
      end

      describe '#ara_attributes' do
        subject { decorator.ara_attributes }

        context "when #parent_uuid is 'uuid'" do
          before { allow(decorator).to receive(:parent_uuid).and_return('uuid') }
          it { is_expected.to include(parent_id: 'uuid') }
        end

        context "when #referent_uuid is 'uuid'" do
          before { allow(decorator).to receive(:referent_uuid).and_return('uuid') }
          it { is_expected.to include(referent_id: 'uuid') }
        end

        context "when #line_uuids is ['uuid']" do
          before { allow(decorator).to receive(:line_uuids).and_return(['uuid']) }
          it { is_expected.to include(line_ids: ['uuid']) }
        end

        context 'when StopArea is a Quay' do
          before { stop_area.area_type = Chouette::AreaType::QUAY }
          it { is_expected.to_not include(collect_children: true) }
        end

        context "when StopArea isn't a Quay" do
          before { stop_area.area_type = Chouette::AreaType::STOP_PLACE }
          it { is_expected.to include(collect_children: true) }
        end
      end
    end

    let(:export_context) { double stop_area_referential: context.stop_area_referential }
    let(:target) { [] }
    subject(:part) do
      Export::Ara::Stops.new export_scope: scope, target: target, context: export_context
    end

    let(:scope) do
      double stop_areas: context.stop_area_referential.stop_areas, codes: context.workgroup.codes
    end

    describe '#stop_areas' do
      subject { part.stop_areas }

      context 'when a StopArea has a parent' do
        let(:context) do
          Chouette.create do
            stop_area :parent, area_type: Chouette::AreaType::STOP_PLACE.to_s
            stop_area :referent, is_referent: true
            stop_area :exported, parent: :parent, referent: :referent
          end
        end

        let(:stop_area) { context.stop_area(:exported) }
        let(:parent) { stop_area.parent }
        let(:referent) { stop_area.referent }

        it 'includes both Stop Area and its parent' do
          is_expected.to include(stop_area, parent, referent)
        end
      end
    end

    context 'when two Stop Areas are exported' do
      let(:context) do
        Chouette.create do
          stop_area(:first)
          stop_area(:other) end
      end

      let(:stop_area) { context.stop_area(:first) }
      let(:other_stop_area) { context.stop_area(:other) }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      describe 'the Ara File target' do
        subject do
          part.export!
          target end
        it { is_expected.to match_array([an_instance_of(Ara::File::StopArea)] * 2) }

        context "when one of the Stop Area has a registration number 'dummy'" do
          before { stop_area.update registration_number: 'dummy' }
          it { is_expected.to include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when all Stop Area has a registration number 'dummy'" do
          before { scope.stop_areas.update_all registration_number: 'dummy' }
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when one of the Stop Area has a code 'test': 'dummy" do
          before { stop_area.codes.create!(code_space: code_space, value: 'dummy') }

          it do
            is_expected.to include(
              an_object_having_attributes(
                codes: { 'test' => 'dummy', 'external' => stop_area.objectid }
              )
            )
          end
        end

        context "when all Stop Areas has a code 'test':'dummy" do
          before do
            scope.stop_areas.each do |stop_area|
              stop_area.codes.create! code_space: code_space, value: 'dummy'
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'test' => 'dummy' })) }
        end
      end
    end
  end

  describe 'Lines export' do
    context 'when two Lines are exported' do
      let(:context) do
        Chouette.create do
          line(:first)
          line(:other) end
      end

      let(:line) { context.line(:first) }
      let(:other_line) { context.line(:other) }

      let(:scope) { double lines: context.line_referential.lines, codes: context.workgroup.codes }
      let(:target) { [] }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      let(:part) { Export::Ara::Lines.new export_scope: scope, target: target }

      describe 'the Ara File target' do
        subject do
          part.export!
          target end
        it { is_expected.to match_array([an_instance_of(Ara::File::Line)] * 2) }

        it 'contains Line having a number' do
          expect(subject.first).to respond_to(:number)
        end

        context "when one of the Line has a registration number 'dummy'" do
          before { line.update registration_number: 'dummy' }
          it { is_expected.to include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when all Line has a registration number 'dummy'" do
          before { scope.lines.update_all registration_number: 'dummy' }
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when one of the Line has a code 'test': 'dummy" do
          before { line.codes.create!(code_space: code_space, value: 'dummy') }

          it do
            is_expected.to include(
              an_object_having_attributes(
                codes: { 'test' => 'dummy', 'external' => line.objectid }
              )
            )
          end
        end

        context "when all Lines has a code 'test': 'dummy" do
          before do
            scope.lines.each do |line|
              line.codes.create! code_space: code_space, value: 'dummy'
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'test' => 'dummy' })) }
        end
      end
    end
  end

  describe 'Companies export' do
    describe Export::Ara::Companies::Decorator do
      subject(:decorator) { described_class.new(company) }
      let(:company) { Chouette::Company.new }

      describe '#ara_attributes' do
        subject { decorator.ara_attributes }

        context "when #name is 'Company Sample'" do
          before { company.name = 'Company Sample' }
          it { is_expected.to include(name: 'Company Sample') }
        end

        context "when #objectid is 'test:Company:1234:LOC'" do
          before { company.objectid = 'test:Company:1234:LOC' }
          it { is_expected.to include(id: '1234') }
        end
      end
    end

    let(:export_context) { double line_referential: context.line_referential }
    let(:target) { [] }
    subject(:part) do
      Export::Ara::Companies.new export_scope: scope, target: target, context: export_context
    end

    let(:scope) do
      double companies: context.line_referential.companies, codes: context.workgroup.codes
    end

    context 'when two Companies are exported' do
      let(:context) do
        Chouette.create do
          company(:first)
          company(:other)
        end
      end

      let(:company) { context.company(:first) }
      let(:other_company) { context.company(:other) }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      describe 'the Ara File target' do
        subject do
          part.export!
          target
        end
        it { is_expected.to match_array([an_instance_of(Ara::File::Operator)] * 2) }

        context "when one of the Company has a registration number 'dummy'" do
          before { company.update registration_number: 'dummy' }
          it { is_expected.to include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when all Company has a registration number 'dummy'" do
          before { scope.companies.update_all registration_number: 'dummy' }
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

        context "when one of the Company has a code 'test': 'dummy" do
          before { company.codes.create!(code_space: code_space, value: 'dummy') }
          it { is_expected.to include(an_object_having_attributes(codes: a_hash_including('test' => 'dummy'))) }
        end

        context "when all Companies has a code 'test':'dummy" do
          before do
            scope.companies.each do |company|
              company.codes.create! code_space: code_space, value: 'dummy'
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'test' => 'dummy' })) }
        end
      end
    end
  end

  describe 'VehicleJourneys export' do
    subject do
      part.export!
      target end

    let(:referential) { context.referential }
    before { referential.switch }

    let(:vehicle_journey) { context.vehicle_journey(:first) }
    let(:other_vehicle_journey) { context.vehicle_journey(:other) }

    let(:scope) { referential }
    let(:target) { [] }

    let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }
    let(:external_code_space) { context.workgroup.code_spaces.create! short_name: 'external' }

    let(:part) { Export::Ara::VehicleJourneys.new export_scope: scope, target: target }

    context 'when one Vehicle Journey is exported' do
      let(:context) do
        Chouette.create { vehicle_journey(:first) }
      end

      describe 'the Ara File target' do
        it { is_expected.to match_array([an_instance_of(Ara::File::VehicleJourney)]) }

        it 'contains a Vehicle journey having a direction_type' do
          expect(subject.first).to respond_to(:direction_type)
        end

        it 'contains a Vehicle journey having a VehicleMode attribute' do
          expect(subject.first.attributes).to eq({ 'VehicleMode': 'bus' })
        end
      end
    end

    context 'when two Vehicle Journeys are exported' do
      let(:context) do
        Chouette.create do
          vehicle_journey(:first)
          vehicle_journey(:other) end
      end

      describe 'the Ara File target' do
        it { is_expected.to match_array([an_instance_of(Ara::File::VehicleJourney)] * 2) }

        context "when one of the Vehicle Journey has a code 'test': 'dummy" do
          before { vehicle_journey.codes.create!(code_space: code_space, value: 'dummy') }

          it do
            is_expected.to include(
              an_object_having_attributes(codes: { 'test' => 'dummy', 'external' => vehicle_journey.objectid})
            )
          end
        end

        context "when all Vehicle Journeys has a code 'test': 'dummy" do
          before do
            scope.vehicle_journeys.each do |vehicle_journey|
              vehicle_journey.codes.create! code_space: code_space, value: 'dummy'
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'test' => 'dummy' })) }
        end

        context "when one of the Vehicle Journey has a code 'external': 'dummy" do
          before { vehicle_journey.codes.create!(code_space: external_code_space, value: 'dummy') }
          it do
            is_expected.to include(
              an_object_having_attributes(codes: { 'external' => 'dummy' })
            )
          end
        end

        context "when all Vehicle Journeys has a code 'external': 'dummy" do
          before do
            scope.vehicle_journeys.each do |vehicle_journey|
              vehicle_journey.codes.create! code_space: external_code_space, value: 'dummy'
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(codes: { 'external' => 'dummy' })) }
        end

      end
    end
  end

  describe 'StopVisit export' do
    describe Export::Ara::StopVisits::Decorator do
      let(:vehicle_journey_at_stop) { Chouette::VehicleJourneyAtStop.new }
      subject(:decorator) { Export::Ara::StopVisits::Decorator.new vehicle_journey_at_stop, day: Date.current }

      describe '#line' do
        subject { decorator.line }

        context 'when Vehicle Journey Line is defined' do
          let(:line) { Chouette::Line.new }

          before do
            vehicle_journey_at_stop.vehicle_journey = Chouette::VehicleJourney.new
            allow(vehicle_journey_at_stop.vehicle_journey).to receive(:line).and_return(line)
          end

          it 'uses this Line' do
            is_expected.to eq(line)
          end
        end

        context 'when Vehicle Journey has no line' do
          it { is_expected.to be_nil }
        end

        context 'without Vehicle Journey' do
          it { is_expected.to be_nil }
        end
      end

      describe '#company' do
        subject { decorator.company }

        context 'when Vehicle Journey has a Company' do
          let(:company) { Chouette::Company.new }
          before do
            vehicle_journey_at_stop.vehicle_journey =
              Chouette::VehicleJourney.new(company: company)
          end
          it 'uses this Company' do
            is_expected.to eq(company)
          end
        end

        context 'when Vehicle Journey has no Company' do
          before do
            vehicle_journey_at_stop.vehicle_journey = Chouette::VehicleJourney.new
          end
          it { is_expected.to be_nil }

          context 'when Line has a Company' do
            let(:company) { Chouette::Company.new }
            before do
              allow(decorator).to receive(:line).and_return(Chouette::Line.new(company: company))
            end
            it 'uses this Company' do
              is_expected.to eq(company)
            end
          end
        end
      end

      describe '#operator_code' do
        subject { decorator.operator_code }

        context 'without Company' do
          it { is_expected.to be_nil }
        end

        context "when Company has a registration number 'dummy'" do
          before { allow(decorator).to receive(:company).and_return(double(registration_number: 'dummy')) }
          it { is_expected.to eq({ 'external' => 'dummy' }) }
        end

        context 'when Company has no registration number' do
          let(:company) { double(registration_number: nil) }
          before { allow(decorator).to receive(:company).and_return(company) }

          context 'when Company has no code' do
            before { allow(company).to receive(:codes).and_return([]) }
            it { is_expected.to be_nil }
          end

          context 'when Company has a code test:dummy' do
            let(:code) { Code.new(code_space: CodeSpace.new(short_name: 'test'), value: 'dummy') }
            before { allow(company).to receive(:codes).and_return([code]) }

            it { is_expected.to eq({ 'test' => 'dummy' }) }
          end
        end
      end

      describe '#references' do
        subject { decorator.references }

        context "when operator_code {'test': 'dummy'}" do
          before { allow(decorator).to receive(:operator_code).and_return({ 'test': 'dummy' }) }
          it { is_expected.to eq({ 'OperatorRef': { 'Type': 'OperatorRef', 'Code': { 'test': 'dummy' } } }) }
        end

        context 'without operator_code' do
          before { allow(decorator).to receive(:operator_code) }
          it { is_expected.to be_nil }
        end
      end

      describe '#ara_attributes' do
        subject { decorator.ara_attributes }

        context 'when references is defined' do
          let(:references) { double }
          before { allow(decorator).to receive(:references).and_return(references) }
          it 'includes its value as references attribute' do
            is_expected.to include(references: references)
          end
        end
      end

      describe '#schedules' do
        subject { decorator.schedules }

        context 'when day is 2030-01-01' do
          before { decorator.day = Date.parse('2030-01-01') }

          context 'when arrival_time is 15:00:00 and departure_time is 15:05:00' do
            before do
              vehicle_journey_at_stop.arrival_time = '15:00:00'
              vehicle_journey_at_stop.departure_time = '15:05:00'
            end

            let(:expected_schedule) do
              {
                Kind: 'aimed',
                ArrivalTime: '2030-01-01T15:00:00+00:00',
                DepartureTime: '2030-01-01T15:05:00+00:00'
              }
            end

            it { is_expected.to include(expected_schedule) }
          end

          context 'when the Stop Visit is a departure with departure_time at 15:00:00' do
            before do
              allow(vehicle_journey_at_stop).to receive(:departure?).and_return(true)
              vehicle_journey_at_stop.departure_time = '15:00:00'
            end

            let(:expected_schedule) do
              {
                Kind: 'aimed',
                DepartureTime: '2030-01-01T15:00:00+00:00'
              }
            end

            it { is_expected.to include(expected_schedule) }
          end

          context 'when the Stop Visit is an arrival with arrival_time at 15:00:00' do
            before do
              allow(vehicle_journey_at_stop).to receive(:arrival?).and_return(true)
              vehicle_journey_at_stop.arrival_time = '15:00:00'
            end

            let(:expected_schedule) do
              {
                Kind: 'aimed',
                ArrivalTime: '2030-01-01T15:00:00+00:00'
              }
            end

            it { is_expected.to include(expected_schedule) }
          end

          context 'when StopArea time zone is "America/Los_Angeles"' do
            let(:stop_area) { Chouette::StopArea.new time_zone: 'America/Los_Angeles' }
            before { vehicle_journey_at_stop.stop_point = Chouette::StopPoint.new(stop_area: stop_area) }

            context 'when arrival_time is 15:00:00 and departure_time is 15:05:00' do
              before do
                vehicle_journey_at_stop.arrival_time = '15:00:00'
                vehicle_journey_at_stop.departure_time = '15:05:00'
              end

              let(:expected_schedule) do
                {
                  Kind: 'aimed',
                  ArrivalTime: '2030-01-01T15:00:00+00:00',
                  DepartureTime: '2030-01-01T15:05:00+00:00'
                }
              end

              it { is_expected.to include(expected_schedule) }
            end
          end
        end
      end
    end

    context 'when Stop Visits are exported' do
      let(:context) do
        Chouette.create { vehicle_journey }
      end
      let(:target) { [] }
      let(:referential) { context.referential }
      let(:vehicle_journey) { context.vehicle_journey }
      let(:day) { Time.new(2022, 6, 30, 2, 2, 2, '+02:00') }

      let(:part) { Export::Ara::StopVisits.new export_scope: referential, target: target }

      before do
        referential.switch
        allow(referential).to receive(:day) { day }
      end

      describe 'the Ara File target' do
        subject do
          part.export!
          target end

        let(:at_stops_count) { vehicle_journey.vehicle_journey_at_stops.count }

        it { is_expected.to match_array([an_instance_of(Ara::File::StopVisit)] * at_stops_count) }

        describe Export::Ara::StopVisits::Decorator do
          context 'with the first stop_visit' do
            let(:vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.first }
            let(:stop_visit_decorator) { Export::Ara::StopVisits::Decorator.new(vehicle_journey_at_stop, day: day) }

            let(:expected_attributes) do
              {
                schedules: [{
                  'Kind': 'aimed',
                  'DepartureTime': '2022-06-30T15:01:00+00:00'
                }],
                passage_order: '1'
              }
            end

            before do
              vehicle_journey_at_stop.update(
                arrival_time: '2000-01-01T19:01:00+000'.to_datetime,
                departure_time: '2000-01-01T15:01:00+0000'.to_datetime
              )
              vehicle_journey_at_stop.stop_point.update position: 0
            end

            it 'should create stop_visits with the correct attributes' do
              expect(stop_visit_decorator.ara_model).to have_attributes(expected_attributes)
            end

            describe '#format_departure_date' do
              let(:test_date) { Time.new(2000, 1, 1, 19, 1, 1, 'Z') }
              subject(:departure_time) { stop_visit_decorator.format_departure_date(test_date) }

              context 'with zero day offset' do
                it { is_expected.to eq('2022-06-30T19:01:01+00:00') }
              end

              context 'with 1 day offset' do
                before { vehicle_journey_at_stop.update(departure_day_offset: 1) }
                it { is_expected.to eq('2022-07-01T19:01:01+00:00') }
              end
            end

            describe '#format_arrival_date' do
              let(:test_date) { Time.new(2000, 1, 1, 19, 1, 1, 'Z') }
              subject(:arrival_time) { stop_visit_decorator.format_arrival_date(test_date) }

              context 'with zero day offset' do
                it { is_expected.to eq('2022-06-30T19:01:01+00:00') }
              end

              context 'with 1 day offset' do
                before { vehicle_journey_at_stop.update(arrival_day_offset: 1) }
                it { is_expected.to eq('2022-07-01T19:01:01+00:00') }
              end
            end
          end

          context 'with the last stop_visit' do
            let(:vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.last }
            let(:stop_visit_decorator) { Export::Ara::StopVisits::Decorator.new(vehicle_journey_at_stop, day: day) }

            let(:expected_attributes) do
              {
                schedules: [{
                  'Kind': 'aimed',
                  'ArrivalTime': '2022-06-30T19:01:00+00:00'
                }],
                passage_order: '3'
              }
            end

            before do
              vehicle_journey_at_stop.update(
                arrival_time: '2000-01-01T19:01:00+000'.to_datetime,
                departure_time: '2000-01-01T15:01:00+0000'.to_datetime
              )
              vehicle_journey_at_stop.stop_point.update position: 2
            end

            it 'should create stop_visits with the correct attributes' do
              expect(stop_visit_decorator.ara_model).to have_attributes(expected_attributes)
            end
          end

        end

        it { is_expected.to match_array([an_instance_of(Ara::StopVisit)] * at_stops_count) }
      end
    end

  end
end
