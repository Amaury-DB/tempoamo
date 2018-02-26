class StopAreaReferential < ActiveRecord::Base
  validates :registration_number_format, format: { with: /\AX*\z/ }

  include ObjectidFormatterSupport
  has_many :stop_area_referential_memberships
  has_many :organisations, through: :stop_area_referential_memberships

  has_many :stop_areas, class_name: 'Chouette::StopArea'
  has_many :stop_area_referential_syncs, -> {order created_at: :desc}
  has_many :workbenches

  def add_member(organisation, options = {})
    attributes = options.merge organisation: organisation
    stop_area_referential_memberships.build attributes
  end

  def last_sync
    stop_area_referential_syncs.last
  end

  def generate_registration_number
    return "" unless registration_number_format.present?
    last = self.stop_areas.order("registration_number DESC NULLS LAST").limit(1).first&.registration_number
    if self.stop_areas.count == 26**self.registration_number_format.size
      raise "NO MORE AVAILABLE VALUES FOR registration_number in referential #{self.name}"
    end

    return "A" * self.registration_number_format.size unless last

    if last == "Z" * self.registration_number_format.size
      val = "AAA"
      while self.stop_areas.where(registration_number: val).exists?
        val = val.next
      end
      val
    else
      last.next
    end
  end

  def validates_registration_number value
    return false unless value.size == registration_number_format.size
    return false unless value =~ /^[A-Z]*$/
    true
  end
end
