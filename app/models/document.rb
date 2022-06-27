class Document < ApplicationModel
	include CodeSupport

	belongs_to :document_type, required: true
	belongs_to :document_provider, required: true

	has_many :codes, as: :resource, dependent: :delete_all

	mount_uploader :file, DocumentUploader

	validates :name, :file, :document_type_id, :document_provider_id, presence: true

	attribute :validity_period, Period::Type.new, range: true

	validates_associated :codes
	# Can't use it for the moment because it fails with an error
  # "convert endless range to an array error due to Array conversion" in AssociatedValidator
	# validates_associated :validity_period
	validates :validity_period, valid: true

	validates :name, :file, :document_type_id, :document_provider_id, presence: true

	def validity_period_attributes=(validity_period_attributes)
		self.validity_period = Period.new(from: validity_period_attributes["from"], to: validity_period_attributes["to"])
	end

	def self.file_extension_whitelist
		%w(pdf kml jpg jpeg png)
	end

end
