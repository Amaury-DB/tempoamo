# frozen_string_literal: true

RSpec.describe Search::WorkgroupImport do
  subject(:search) { described_class.new }

  describe 'validation' do
    context 'when period is not valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => false)) }
      it { is_expected.to_not be_valid }
    end
    context 'when period is valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => true)) }
      it { is_expected.to be_valid }
    end
  end

  describe '#period' do
    subject { search.period }

    context 'when no start and end dates are defined' do
      before { search.start_date = search.end_date = nil }
      it { is_expected.to be_nil }
    end

    context 'when start date is defined' do
      before { search.start_date = Time.zone.today }
      it { is_expected.to have_same_attributes(:start_date, than: search) }
    end

    context 'when end date is defined' do
      before { search.end_date = Time.zone.today }
      it { is_expected.to have_same_attributes(:end_date, than: search) }
    end
  end

  describe '#candidate_statuses' do
    subject { search.candidate_statuses }

    Operation::UserStatus.all.each do |user_status| # rubocop:disable Rails/FindEach
      it "includes user status #{user_status}" do
        is_expected.to include(user_status)
      end
    end
  end

  describe '#candidate_workbenches' do
    subject { search.candidate_workbenches }

    before { search.workgroup = double(workbenches: double('Workgroup workbenches')) }

    it { is_expected.to eq(search.workgroup.workbenches) }
  end

  describe '#workbenches' do
    subject { search.workbenches }

    let(:context) do
      Chouette.create do
        workgroup(:first) { workbench }
        workgroup(:other) { workbench }
      end
    end

    let(:workgroup) { context.workgroup(:first) }
    let(:search) { described_class.new(workgroup: workgroup) }

    context 'when workbench_ids is nil' do
      before { search.workbench_ids = nil }
      it { is_expected.to be_empty }
    end

    context 'when workbench_ids is empty' do
      before { search.workbench_ids = [] }
      it { is_expected.to be_empty }
    end

    context 'when workbench_ids contains the Workbench identifier from the associated Workgroup' do
      let(:workbench) { workgroup.workbenches.first }
      before { search.workbench_ids = [workbench.id] }

      it 'includes this Workbench' do
        is_expected.to include(workbench)
      end
    end

    context 'when workbench_ids contains the Workbench identifier from another Workgroup' do
      let(:workbench) { context.workgroup(:other).workbenches.first }
      before { search.workbench_ids = [workbench.id] }

      it "doesn't include this Workbench" do
        is_expected.to_not include(workbench)
      end
    end
  end

  describe '#query' do
    describe 'build' do
      let(:scope) { double }
      let(:query) { Query::Mock.new(scope) }

      before do
        allow(Query::Import).to receive(:new).and_return(query)
      end

      it 'uses Search workbenches' do
        allow(search).to receive(:workbenches).and_return(double)
        expect(query).to receive(:workbenches).with(search.workbenches).and_return(query)
        search.query(scope)
      end

      it 'uses Search name as text' do
        search.name = 'dummy'
        expect(query).to receive(:text).with(search.name).and_return(query)
        search.query(scope)
      end

      it 'uses Search statuses as user statuses' do
        allow(search).to receive(:statuses).and_return(double)
        expect(query).to receive(:user_statuses).with(search.statuses).and_return(query)
        search.query(scope)
      end

      it 'uses Search period' do
        allow(search).to receive(:period).and_return(double)
        expect(query).to receive(:in_period).with(search.period).and_return(query)
        search.query(scope)
      end
    end
  end
end