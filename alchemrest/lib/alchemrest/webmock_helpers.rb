# frozen_string_literal: true

module Alchemrest
  module WebmockHelpers
    module_function def stub_alchemrest_request(alchemrest_request, with_request_body: false, with_headers: false)
      stub_url = if defined?(alchemrest_request.url)
                   alchemrest_request.url
                 else
                   Addressable::Template.new("http://{host}#{alchemrest_request.path}")
                 end

      http_method = alchemrest_request.http_method.to_sym

      stub = if with_request_body
               stub_request(http_method, stub_url).with(body: alchemrest_request.body)
             else
               stub_request(http_method, stub_url)
             end

      if with_headers
        stub.with(headers: alchemrest_request.headers)
      else
        stub
      end
    end
  end
end
