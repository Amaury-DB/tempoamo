require 'net/http'
class NetexImport < Import
  after_commit :launch_java_import, on: :create

  validates_presence_of :parent

  def launch_java_import
    logger.warn  "Call iev get #{Rails.configuration.iev_url}/boiv_iev/referentials/importer/new?id=#{id}"

    Thread.new do
      begin
        Net::HTTP.get(URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/importer/new?id=#{id}"))
      rescue Exception => e
        logger.error "IEV server error : #{e.message}"
        logger.error e.backtrace.inspect
      end
    end
  end
end
