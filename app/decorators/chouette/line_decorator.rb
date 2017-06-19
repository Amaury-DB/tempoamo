class Chouette::LineDecorator < Draper::Decorator
  delegate_all

  # Requires:
  #   context: {
  #     line_referential:
  #   }
  def action_links
    links = []

    links << Link.new(
      content: h.t('lines.actions.show_network'),
      href: [context[:line_referential], object.network]
    )

    links << Link.new(
      content: h.t('lines.actions.show_company'),
      href: [context[:line_referential], object.company]
    )

    if h.policy(Chouette::Line).create? &&
        context[:line_referential].organisations.include?(current_organisation)
      links << Link.new(
        content: h.t('lines.actions.new'),
        href: h.new_line_referential_line_path(context[:line_referential])
      )
    end

    # TODO: what if false? do we delete this?
    if false && h.policy(object).update?
      # = link_to t('lines.actions.edit'), edit_line_referential_line_path(context[:line_referential], object), class: 'btn btn-primary'
    end

    if h.policy(object).destroy?
      links << Link.new(
# TODO: this translation is different!
span = t('lines.actions.destroy')
        content: h.destroy_link_content,
        href: h.line_referential_line_path(context[:line_referential], object),
        method: :delete,
        data: { confirm:  h.t('lines.actions.destroy_confirm') }
      )
    end

    links
  end
end
