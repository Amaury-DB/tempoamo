# frozen_string_literal: true

RSpec.describe Macro::CreateCodeFromSequence do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateCodeFromSequence::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          target_model: target_model,
          code_space_id: code_space.id,
          format: format,
          sequence_id: sequence.id
        }
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create(referential: referential, workbench: workbench)
    end

    let(:context) do
      Chouette.create do
        code_space short_name: 'test'

        stop_area :first
        stop_area :second, codes: { test: 'dummy:1' }
        stop_area :last, codes: { test: 'dummy:2' }

        referential do
          route stop_areas: %i[first second last]
        end
      end
    end

    let(:format) { 'dummy:%{value}' }
    let(:sequence) do
      Sequence.create(
        name: 'Regional identifiers',
        sequence_type: 'range_sequence',
        range_start: 1,
        range_end: 10,
        workbench: workbench
      )
    end

    let(:code_space) { context.code_space }
    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:model_name) { model.name }

    describe '#run' do
      subject { macro_run.run }

      before { referential.switch }

      let(:expected_message) do
        an_object_having_attributes(
          message_attributes: {
            'model_name' => model_name,
            'code_value' => 'dummy:3'
          }
        )
      end

      describe 'StopArea' do
        let(:target_model) { 'StopArea' }
        let(:model) { context.stop_area(:first) }
        let(:code_value) { 'dummy:2' }

        it 'should create code' do
          expect { subject }.to change { model.codes.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
