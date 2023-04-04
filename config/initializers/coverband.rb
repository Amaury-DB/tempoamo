if ENV['COVERBAND_REDIS_URL']
  Coverband.configure do |config|
    config.track_views = true
    config.track_routes = true
    # config.track_translations = true

    config.ignore += %w[config/application.rb
                        config/boot.rb
                        config/puma.rb
                        bin/*
                        config/environments/*
                        lib/tasks/*
                        spec/*]
  end
end
