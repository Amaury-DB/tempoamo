# frozen_string_literal: true

module Policy
  class LineReferential < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      [
        ::Chouette::Company,
        ::LineProvider,
        ::Chouette::Line
      ].include?(resource_class)
    end
  end
end
