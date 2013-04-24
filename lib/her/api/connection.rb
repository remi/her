module Her
  class API
    class Connection < Faraday::Connection
      # Make a request to the API and return the parsed_data and the whole response
      #
      # @private
      def request(opts)
        method = opts.delete(:_method)
        path = opts.delete(:_path)
        headers = opts.delete(:_headers)
        opts.delete_if { |key, value| key.to_s =~ /^_/ } # Remove all internal parameters

        response = send(method) do |request|
          request.headers.merge!(headers) if headers

          if method == :get
            # For GET requests, treat additional parameters as querystring data
            request.url path, opts
          else
            # For other requests, treat additional parameters as request body
            request.url path
            request.body = opts
          end
        end

        { :parsed_data => response.env[:body], :response => response }
      end
    end
  end
end
