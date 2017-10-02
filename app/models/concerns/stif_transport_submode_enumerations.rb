module StifTransportSubmodeEnumerations
  extend ActiveSupport::Concern
  extend Enumerize

  enumerize :transport_submode, in: %w(unknown undefined internationalFlight domesticFlight intercontinentalFlight domesticScheduledFlight shuttleFlight intercontinentalCharterFlight internationalCharterFlight roundTripCharterFlight sightseeingFlight helicopterService domesticCharterFlight SchengenAreaFlight airshipService shortHaulInternationalFlight canalBarge localBus regionalBus expressBus nightBus postBus specialNeedsBus mobilityBus mobilityBusForRegisteredDisabled sightseeingBus shuttleBus highFrequencyBus dedicatedLaneBus schoolBus schoolAndPublicServiceBus railReplacementBus demandAndResponseBus airportLinkBus internationalCoach nationalCoach shuttleCoach regionalCoach specialCoach schoolCoach sightseeingCoach touristCoach commuterCoach metro tube urbanRailway local highSpeedRail suburbanRailway regionalRail interregionalRail longDistance intermational sleeperRailService nightRail carTransportRailService touristRailway railShuttle replacementRailService specialTrain crossCountryRail rackAndPinionRailway cityTram localTram regionalTram sightseeingTram shuttleTram trainTram internationalCarFerry nationalCarFerry regionalCarFerry localCarFerry internationalPassengerFerry nationalPassengerFerry regionalPassengerFerry localPassengerFerry postBoat trainFerry roadFerryLink airportBoatLink highSpeedVehicleService highSpeedPassengerService sightseeingService schoolBoat cableFerry riverBus scheduledFerry shuttleFerryService telecabin cableCar lift chairLift dragLift telecabinLink funicular streetCableCar allFunicularServices undefinedFunicular)

  def transport_submodes
    StifTransportSubmodeEnumerations.transport_submode.options.map(&:first)
  end
end
