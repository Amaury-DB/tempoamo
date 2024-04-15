# frozen_string_literal: true

class AccessibilityAssessmentDecorator < AF83::Decorator
  decorates AccessibilityAssessment

  set_scope { [context[:workbench], context[:referential]] }

  create_action_link

  with_instance_decorator(&:crud)
end
