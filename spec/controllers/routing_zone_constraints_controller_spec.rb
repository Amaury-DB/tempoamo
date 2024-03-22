RSpec.describe RoutingConstraintZonesController do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        referential do
          routing_constraint_zone
        end
      end
    end
  end

  let!(:routing_constraint_zone) { context.routing_constraint_zone }
  let(:route) { context.route }
  let(:referential) { context.referential }
  let(:q) { {} }

  describe 'GET index' do
    let(:request) { get :index, params: { referential_id: referential.id, line_id: route.line_id, q: q } }

    before { referential.update objectid_format: :netex }

    context 'without filter' do
      it 'should include the rcz' do
        expect(request).to be_successful
        expect(assigns(:routing_constraint_zones)).to include(routing_constraint_zone)
      end
    end

    context 'with a name filter' do
      let(:q) { { name_or_short_id_cont: 'foo', route_id_eq: '' } }
      it 'should not include the rcz' do
        expect(request).to be_successful
        expect(assigns(:routing_constraint_zones)).to_not include(routing_constraint_zone)
      end
    end
  end
end
