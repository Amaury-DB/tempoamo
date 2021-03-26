FactoryBot.define do
  factory :publication_setup do
    sequence(:name) { |n| "Publication #{n}" }
    workgroup { create(:workgroup) }
    enabled {false}
    export_type {"Export::Gtfs"}
    export_options { { duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }

    transient do
      destinations_count { 1 }
    end

    after(:build) do |ps, evaluator|
      destinations_count = evaluator.destinations_count || 0
      destinations_count.times do
        ps.destinations << build(:destination, publication_setup: ps)
      end
    end
  end

  factory :publication_setup_gtfs, :parent => :publication_setup do
    export_type {"Export::Gtfs"}
    export_options { { duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }
  end

  factory :publication_setup_idfm_netex_full, :parent => :publication_setup do
    export_type {"Export::Netex"}
    export_options { {export_type: :full, duration: 60} }
  end

  factory :publication_setup_idfm_netex_line, :parent => :publication_setup do
    export_type {"Export::Netex"}
    export_options { {export_type: :line, duration: 60, line_code: 1 } }
  end

  factory :publication_setup_netex_full, :parent => :publication_setup do
    export_type {"Export::NetexFull"}
    export_options { { duration: 200 } }
  end

end
