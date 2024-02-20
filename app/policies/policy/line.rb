# frozen_string_literal: true

module Policy
  class Line < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::LineProvider
    authorize_by Strategy::Permission

    def update_activation_dates?
      around_can(:update_activation_dates) { true }
    end

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
