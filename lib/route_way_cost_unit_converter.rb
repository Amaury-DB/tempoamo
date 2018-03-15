class RouteWayCostUnitConverter
  def self.convert(way_costs)
    return if way_costs.nil?

    way_costs.each do |_, costs|
      costs['distance'] = self.meters_to_kilometers(costs['distance'])
      costs['time'] = self.seconds_to_minutes(costs['time'])
    end
  end

  private

  # Round to 2 decimal places to appease JavaScript validation
  def self.meters_to_kilometers(num)
    (num / 1000.0).round(2)
  end

  def self.seconds_to_minutes(num)
    num / 60
  end
end
