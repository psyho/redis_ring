module RedisRing

  class HttpClient

    def get(host, port, path, params = {})
      Net::HTTP.get(uri(host, port, path, params))
    end

    def post(host, port, path, params = {})
      Net::HTTP.post_form(uri(host, port, path, params), {}).body
    end

    protected

    def uri(host, port, path, params)
      params_str = params.map{|k,v| "#{k}=#{v}"}.join("&")
      params_str = "?" + params_str unless params_str.empty?
      URI.parse("http://#{host}:#{port}#{path}#{params_str}")
    end

  end

end
