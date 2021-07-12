require "tablo"
require "../diagnostic_logger"

module Printer
  extend Logging

  def self.run(stats_stream)
    Channel(Nil).new.tap { |done|
      spawn do
        loop do
          data = stats_stream.receive.map { |(k, v)|
            [k, v[:success], v[:failure]]
          }
          table = Tablo::Table.new(data) do |t|
            t.add_column("Url", width: 24) { |n| n[0] }
            t.add_column("Success") { |n| n[1] }
            t.add_column("Failure") { |n| n[2] }
          end
          puts table
        end
      rescue Channel::ClosedError
        logger.info("input stream was closed.")
      ensure
        done.close
      end
    }
  end
end
