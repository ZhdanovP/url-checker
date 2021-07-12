require "http/client"
require "../diagnostic_logger"

module StatusChecker
  extend Logging

  private def self.get_status(url : String)
    response = HTTP::Client.get url
    {url, response.status_code}
  rescue e : IO::Error | Socket::Addrinfo::Error | OpenSSL::SSL::Error
    {url, e}
  end

  def self.run(url_stream, workers : Int32)
    countdown = Channel(Nil).new(workers)
    Channel({String, Int32 | Exception}).new.tap { |url_status_stream|
      spawn(name: "supervisor") do
        workers.times {
          countdown.receive
        }
        url_status_stream.close
      end

      workers.times { |w_i|
        spawn(name: "worker_#{w_i}") do
          loop do
            url = url_stream.receive
            result = get_status(url)

            url_status_stream.send result
          end
        rescue Channel::ClosedError
          logger.info("in stream was closed")
        ensure
          countdown.send nil
        end
      }
    }
  end
end
