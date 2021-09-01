module Search
  class Base
    extend ActiveModel::Naming
    include ActiveModel::AttributeAssignment
    include ActiveModel::Validations

    def initialize(scope, attributes = nil)
      @scope = scope
      attributes ||= {}

      # Transform 'legacy' parameters into order attributes
      if attributes["sort"]
        sort_attribute = attributes.delete("sort").to_sym
        sort_direction = attributes.delete("direction").presence || :asc

        attributes["order"] = { sort_attribute => sort_direction.to_sym }
      end

      order.attributes = attributes.delete "order" if attributes["order"]
      self.attributes = attributes
    end
    attr_reader :scope

    # Requires to create a form
    def to_key; end

    validates_numericality_of :page, greater_than_or_equal_to: 0, allow_nil: true
    validates_numericality_of :per_page, greater_than_or_equal_to: 0, allow_nil: true

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Search')
    end

    def query
      raise "Not yet implemented"
    end

    def collection
      if valid?
        query.scope.order(order.to_hash).paginate(paginate_attributes)
      else
        scope.none
      end
    end

    def order
      # Use the local/specific Order class
      @order ||= self.class.const_get("Order").new
    end

    attr_accessor :page
    attr_writer :per_page

    def per_page
      @per_page ||= 30
    end

    def paginate_attributes
      { per_page: per_page, page: page }
    end
  end

  class Order
    def initialize(attributes = {})
      self.attributes = attributes
    end

    def attributes=(attributes = {})
      attributes.each do |attribute, attribute_order|
        attribute_method = "#{attribute}="
        # Ignore invalid attribute
        send attribute_method, attribute_order if respond_to?(attribute_method)
      end
    end

    cattr_reader :attributes, default: []

    # TODO: Attributes can only return values :asc, :desc or nil (for securiy reason)
    # Attributes can be set with "asc", :asc, 1 to have the :asc value
    # Attributes can be set with "desc", :desc, -1 to have the :desc value
    # Attributes can be set with nil, 0 to have the nil value
    #
    # These methods ensures that the sort attribute is supported and valid
    def self.attribute(name)
      name = name.to_sym

      attr_accessor name
      attributes << name
    end

    def to_hash
      attributes.map do |attribute|
        if (attribute_order = send(attribute))
          [ attribute, attribute_order ]
        end
      end.compact.to_h
    end
  end
end
