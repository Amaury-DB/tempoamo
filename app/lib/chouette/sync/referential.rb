module Chouette
  module Sync
    class Referential
      attr_reader :target, :options

      def initialize(target, options = {})
        @target = target
        @options = options
      end
      attr_accessor :source, :code_space, :default_provider, :event_handler

      def synchronize_with(sync_class)
        sync_classes << sync_class
      end

      def update_or_create
        syncs.each do |sync|
          sync.code_space = code_space
          sync.default_provider = default_provider

          sync.update_or_create
        end
      end

      def after_synchronisation
        syncs.each(&:after_synchronisation)
      end

      def delete(resource_type, deleted_ids)
        syncs.each do |sync|
          sync.delete deleted_ids if sync.resource_type == resource_type
        end
      end

      def synchronize
        syncs.each(&:synchronize)
      end

      protected

      def sync_classes
        @sync_classes ||= []
      end

      def syncs
        @syncs ||= sync_classes.map do |sync_class|
          create_sync sync_class
        end
      end

      def sync_options
        options.merge({
                        event_handler: event_handler,
                        target: target,
                        source: source,
                        code_space: code_space,
                        default_provider: default_provider
                      })
      end

      def create_sync(sync_class)
        sync_class.new sync_options
      end
    end
  end
end
