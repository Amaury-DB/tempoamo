class Entrance < ActiveRecord::Base
  include StopAreaReferentialSupport
  include ObjectidSupport
  extend Enumerize

  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false
  has_one :raw_import, as: :model, dependent: :delete

  has_many :codes, as: :resource, dependent: :delete_all
  accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
  validates_associated :codes

  enumerize :entrance_type, in: %i(opening open_door door swing_door revolving_door automatic_door ticket_barrier gate other), scope: true

  validates :name, presence: true
  validates_format_of :position_input, :with => %r{\A *-?(0?[0-9](\.[0-9]*)?|[0-8][0-9](\.[0-9]*)?|90(\.[0]*)?) *\, *-?(0?[0-9]?[0-9](\.[0-9]*)?|1[0-7][0-9](\.[0-9]*)?|180(\.[0]*)?) *\Z}, allow_nil: true, allow_blank: true
  attr_writer :position_input

  def position_input
    @position_input || ("#{position.y} #{position.x}" if position)
  end

  def longitude
    position&.x
  end
  def latitude
    position&.y
  end

  def entry?
    entry_flag
  end

  def exit?
    exit_flag
  end

  before_validation :position_from_input
  def position_from_input
    PositionInput.new(@position_input).change_position(self)
  end

end
