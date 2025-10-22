# frozen_string_literal: true

require 'httparty'

module WhatsappIa
  class Client
    include HTTParty

    attr_reader :base_url, :api_key, :session_ia_id

    def initialize(api_key: 'dRla3QaYT5DA0pGGDTLAjxFAK998BAig', session_ia_id: '68decdaa3c8480f9c1811b15', base_url: 'https://marce.ai')
      @base_url = base_url
      @api_key = api_key
      @session_ia_id = session_ia_id
      
      raise "API key is required" if @api_key.nil? || @api_key.empty?
      raise "Session IA ID is required" if @session_ia_id.nil? || @session_ia_id.empty?
      
      self.class.base_uri(@base_url)
      self.class.headers({
        'Authorization' => "Bearer #{@api_key}",
        'X-Session-Ia-Id' => @session_ia_id,
        'Accept' => 'application/json'
      })
    end

    def send_message(chat_id:, message:, file_path: nil)
      endpoint = '/api/v1/whatsapp_ia/messages'
      
      payload = {
        chat_id: chat_id,
        message: message
      }
      
      if file_path
        payload[:file] = File.open(file_path)
      end
      
      # Always use multipart form data to match the curl command exactly
      headers = authorization_headers_multipart
      
      response = self.class.post(endpoint, {
        body: payload,
        headers: headers
      })
      
      log_curl_and_response('POST', endpoint, payload, headers, response)
      
      response
    end

    private

    def authorization_headers
      {
        'Authorization' => "Bearer #{api_key}",
        'X-Session-Ia-Id' => session_ia_id,
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def authorization_headers_multipart
      {
        'Authorization' => "Bearer #{api_key}",
        'X-Session-Ia-Id' => session_ia_id,
        'Accept' => 'application/json'
      }
    end

    def generate_curl_command(method, endpoint, payload = nil, headers = {})
      full_url = "#{base_url}#{endpoint}"
      
      curl_parts = [
        "curl -X #{method.upcase} \"#{full_url}\""
      ]
      
      headers.each do |key, value|
        curl_parts << "-H \"#{key}: #{value}\""
      end
      
      if payload && !payload.empty?
        if payload.is_a?(Hash) && payload.values.any? { |v| v.is_a?(File) }
          # Handle multipart form data
          payload.each do |key, value|
            if value.is_a?(File)
              curl_parts << "-F \"#{key}=@#{value.path}\""
            else
              curl_parts << "-F \"#{key}=#{value}\""
            end
          end
        else
          # Handle JSON data
          if payload.is_a?(Hash)
            payload.each do |key, value|
              curl_parts << "-F \"#{key}=#{value}\""
            end
          else
            curl_parts << "--data-raw '#{payload.to_json}'"
          end
        end
      end
      
      curl_parts.join(" \\\n  ")
    end

    def log_curl_and_response(method, endpoint, payload, headers, response)
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      logger.info "🐚 === WHATSAPP IA CURL COMMAND ==="
      logger.info generate_curl_command(method, endpoint, payload, headers)
      logger.info ""
      logger.info "📥 === RESPONSE ==="
      logger.info "Status: #{response.code}"
      logger.info "Body: #{response.body}"
      logger.info "🔚 === END ==="
    end
  end
end