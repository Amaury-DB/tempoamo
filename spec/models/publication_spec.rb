# frozen_string_literal: true

RSpec.describe Publication, type: :model do
  it { should belong_to :publication_setup }
  it { should belong_to :parent }
  it { should have_one :export }
  it { should validate_presence_of :publication_setup }
  it { should validate_presence_of :parent }

  it { is_expected.to have_one(:workgroup) }
  it { is_expected.to have_one(:organisation) }

  let(:export_type) { 'Export::Gtfs' }
  let(:export_options) do
    { type: export_type, duration: 90, prefer_referent_stop_area: false, ignore_single_stop_station: false }
  end
  let(:publication_setup) { create :publication_setup, export_options: export_options }
  let(:publication) { create :publication, parent: operation, publication_setup: publication_setup, creator: 'test' }
  let(:referential) { first_referential }
  let(:operation) { create :aggregate, referentials: [first_referential] }

  before(:each) do
    operation.update status: :successful
    allow(operation).to receive(:new) { referential }

    2.times do
      referential.metadatas.create line_ids: [create(:line, line_referential: referential.line_referential).id],
                                   periodes: [Time.now..1.month.from_now]
    end

    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail', result: :expected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail unexpectedly',
                                           result: :unexpected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will succeed', result: :successful
  end

  describe '#perform' do
    subject { publication.perform }

    it 'should create an export' do
      expect_any_instance_of(Export::Gtfs).to receive(:run)
      subject
      expect(publication.export).to be_present
    end

    context 'when the export succeeds' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          obj.update status: :successful
        end
      end

      it 'should call send_to_destinations' do
        expect(publication).to receive(:send_to_destinations)
        subject
      end
    end

    context 'when the export raises an error' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |_obj|
          raise 'ooops'
        end
      end

      it 'should fail' do
        expect(publication).to_not receive(:send_to_destinations)
        subject
        expect(publication.user_status).to be_failed
        expect(publication.export).to be_present
        expect(publication.export).to be_persisted
      end
    end

    context 'when the export fails' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          obj.update status: :failed
        end
      end

      it 'should fail' do
        expect(publication).to_not receive(:send_to_destinations)
        subject
        expect(publication.user_status).to be_failed
        expect(publication.export).to be_present
      end
    end
  end

  describe '#send_to_destinations' do
    it 'should call each destination' do
      publication_setup.destinations.each do |destination|
        expect(destination).to receive(:transmit).with(publication).and_call_original
      end

      expect { publication.send_to_destinations }.to change {
                                                       DestinationReport.where(publication_id: publication.id).count
                                                     }.by publication_setup.destinations.count
    end
  end

  describe '#change_status' do
    subject { publication.change_status(Operation.status.done) }

    let(:export) { create(:gtfs_export) }

    before do
      publication.send_to_destinations
      allow(export).to receive(:status).and_return 'successful'
      allow(publication).to receive(:export).and_return export
    end

    context 'with a failed destination_report' do
      it 'should set status to warning' do
        expect { subject }.to change { publication.user_status }.to 'warning'
      end
    end

    context 'with only successful destination_reports' do
      before(:each) do
        allow_any_instance_of(DestinationReport).to receive(:status) { 'successful' }
      end

      it 'should set status to successful' do
        expect { subject }.to change { publication.user_status }.to 'successful'
      end
    end
  end
end
