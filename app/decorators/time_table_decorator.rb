# frozen_string_literal: true

class TimeTableDecorator < AF83::Decorator
  decorates Chouette::TimeTable

  set_scope { [context[:referential]] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link policy: :actualize, if: ->{ object.calendar }, secondary: true do |l|
      l.content t('actions.actualize')
      l.href do
         h.actualize_referential_time_table_path(
          context[:referential],
          object
        )
      end
      l.method :post
    end

    instance_decorator.action_link policy: :duplicate, secondary: true do |l|
      l.content t('actions.duplicate')
      l.href do
        h.duplicate_referential_time_table_path(
          context[:referential],
          object
        )
      end
      l.icon :clone
    end
  end
end
