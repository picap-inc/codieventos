# frozen_string_literal: true

require 'httparty'

module WhatsappIa
  class Client
    include HTTParty

    attr_reader :base_url, :api_key, :session_ia_id

    def initialize(api_key:, session_ia_id:, base_url: 'https://marce.ai')
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

    def send_text_message(chat_id:, message:)
      endpoint = '/api/v1/whatsapp_ia/messages'
      
      payload = {
        chat_id: chat_id,
        message: message
      }
      
      headers = authorization_headers
      
      response = self.class.post(endpoint, {
        body: payload,
        headers: headers
      })
      
      log_curl_and_response('POST', endpoint, payload, headers, response)
      
      response
    end

    def send_message_with_file(chat_id:, message:, file_path:)
      endpoint = '/api/v1/whatsapp_ia/messages'
      
      payload = {
        chat_id: chat_id,
        message: message,
        file: File.open(file_path)
      }
      
      headers = authorization_headers_multipart
      
      response = self.class.post(endpoint, {
        body: payload,
        headers: headers
      })
      
      log_curl_and_response('POST', endpoint, payload, headers, response)
      
      response
    end

    def send_file_only(chat_id:, file_path:, caption: nil)
      endpoint = '/api/v1/whatsapp_ia/messages'
      
      payload = {
        chat_id: chat_id,
        file: File.open(file_path)
      }
      
      payload[:message] = caption if caption
      
      headers = authorization_headers_multipart
      
      response = self.class.post(endpoint, {
        body: payload,
        headers: headers
      })
      
      log_curl_and_response('POST', endpoint, payload, headers, response)
      
      response
    end

    def get_session_status
      endpoint = '/api/v1/whatsapp_ia/sessions/status'
      
      headers = authorization_headers
      
      response = self.class.get(endpoint, {
        headers: headers
      })
      
      log_curl_and_response('GET', endpoint, nil, headers, response)
      
      response
    end

    def get_chats(limit: 50, offset: 0)
      endpoint = '/api/v1/whatsapp_ia/chats'
      
      query = {
        limit: limit,
        offset: offset
      }
      
      headers = authorization_headers
      
      response = self.class.get(endpoint, {
        query: query,
        headers: headers
      })
      
      log_curl_and_response('GET', endpoint, query, headers, response)
      
      response
    end

    def get_chat_messages(chat_id:, limit: 50, offset: 0)
      endpoint = "/api/v1/whatsapp_ia/chats/#{chat_id}/messages"
      
      query = {
        limit: limit,
        offset: offset
      }
      
      headers = authorization_headers
      
      response = self.class.get(endpoint, {
        query: query,
        headers: headers
      })
      
      log_curl_and_response('GET', endpoint, query, headers, response)
      
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
        # Note: Don't set Content-Type for multipart, HTTParty handles it automatically
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
      Rails.logger.info "🐚 === WHATSAPP IA CURL COMMAND ==="
      Rails.logger.info generate_curl_command(method, endpoint, payload, headers)
      Rails.logger.info ""
      Rails.logger.info "📥 === RESPONSE ==="
      Rails.logger.info "Status: #{response.code}"
      Rails.logger.info "Body: #{response.body}"
      Rails.logger.info "🔚 === END ==="
    end
  end
end