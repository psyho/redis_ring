class FakeHttpClient < RedisRing::HttpClient

  def posts
    @posts ||= []
  end

  def gets
    @gets ||= []
  end

  def responses
    @responses ||= Hash.new("OK")
  end

  def post(host, port, path, params = {})
    url = uri(host, port, path, params).to_s
    posts << url
    return responses[url]
  end

  def get(host, port, path, params = {})
    url = uri(host, port, path, params).to_s
    gets << url
    return responses[url]
  end

  def set_response(url, text)
    responses[url] = text
  end

  def sent_post?(url)
    posts.include?(url)
  end

  def sent_get?(url)
    gets.include?(url)
  end

end
