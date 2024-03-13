# frozen_string_literal: true

class Sequence < ApplicationModel
  extend Enumerize

  belongs_to :workbench, optional: false, class_name: 'Workbench'

  validates :name, :sequence_type, presence: true

  enumerize :sequence_type, in: %i[range_sequence], scope: true

  validates :range_start, :range_end, numericality: { only_integer: true }

  def range_values
    "#{range_start}-#{range_end}"
  end

  def values(offset: 1, limit: 1000)
    value_start = range_start + (offset - 1) * limit
    value_end = value_start + limit - 1
    value_end = range_end if value_end > range_end

    (value_start..value_end).to_a
  end
end
