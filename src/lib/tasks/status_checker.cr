require "http/client"

module StatusChecker
  private def self.get_status(url : String)
    response = HTTP::Client.get url
    {url, response.status_code}
  rescue e : IO::Error | Socket::Addrinfo::Error | OpenSSL::SSL::Error
    {url, e}
  end

  def self.run(url_stream, result_stream)
    spawn do
      loop do
        url = url_stream.receive
        result = get_status(url)

        result_stream.send result
      end
    end
  end
end
