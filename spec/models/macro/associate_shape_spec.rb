RSpec.describe Macro::AssociateShape do
  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::AssociateShape::Run do
    let(:macro_list_run) do
      Macro::List::Run.new referential: context.referential, workbench: context.workbench
    end
    subject(:macro_run) { Macro::AssociateShape::Run.new macro_list_run: macro_list_run }

    describe ".run" do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          code_space short_name: "external"
          referential do
            journey_pattern
          end
          shape
        end
      end

      let(:code_space) { context.code_space }
      let(:journey_pattern) { context.journey_pattern }
      let(:shape) { context.shape }

      before { context.referential.switch }

      context "when the JourneyPattern has no Shape" do
        context "when the Shape has the Journey Pattern name as external code" do
          before { shape.codes.create! code_space: code_space, value: journey_pattern.name }
          it "updates the Journey Pattern to use the Shape" do
            expect { subject }.to change { journey_pattern.reload.shape }.from(nil).to(shape)
          end
        end

        context "when no Shape has the Journey Pattern name as external code" do
          it "doesn't change the Journey Pattern Shape" do
            expect { subject }.to_not change { journey_pattern.reload.shape }
          end
        end
      end

      context "when the JourneyPattern has already a Shape" do
        before { journey_pattern.update! shape: shape }

        it "doesn't change the Journey Pattern Shape" do
          expect { subject }.to_not change { journey_pattern.reload.shape }
        end
      end
    end
  end
end
