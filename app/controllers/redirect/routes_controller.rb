module Redirect
  class RoutesController < BaseController
    include ReferentialSupport

    def route
      Chouette::Route.find(params[:id])
    end

    def show
      redirect_to referential_line_route_path referential, route.line, route
    end
  end
end
