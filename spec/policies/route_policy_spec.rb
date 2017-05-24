RSpec.describe RoutePolicy, type: :policy do

  permissions :create? do
    it_behaves_like 'permitted policy', 'routes.create', restricted_ready: true
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'routes.destroy', restricted_ready: true
  end

  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', 'routes.edit', restricted_ready: true
  end

  permissions :new? do
    it_behaves_like 'permitted policy', 'routes.create', restricted_ready: true
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'routes.edit', restricted_ready: true
  end
end
