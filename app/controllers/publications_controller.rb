# frozen_string_literal: true

class PublicationsController < Chouette::WorkgroupController
  defaults :resource_class => Publication
  belongs_to :publication_setup

  respond_to :html

  def show
    @export = ExportDecorator.decorate(
      publication.export,
      context: {
        parent: workgroup
      }
    )
    show!
  end

  alias publication resource

end
