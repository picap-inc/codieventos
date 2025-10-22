# WhatsApp IA Client

A Ruby client library for interacting with the WhatsApp IA API using HTTParty.

## Overview

This client provides a simple interface to interact with WhatsApp IA's messaging services. It implements all the core API endpoints for sending messages, files, and managing WhatsApp conversations through the IA platform.

## Installation

The client uses HTTParty which should already be available in your Rails application. If not, add it to your Gemfile:

```ruby
gem 'httparty'
```

## Usage

### Initialize the Client

```ruby
require_relative 'lib/whatsapp_ia/client'

client = WhatsappIa::Client.new(
  api_key: 'YOUR_API_KEY',
  session_ia_id: '68ded1910b0cb4a87c7df630',
  base_url: 'https://marce.ai'  # optional, defaults to 'https://marce.ai'
)
```

### Send Text Message

Send a simple text message to a WhatsApp chat:

```ruby
response = client.send_text_message(
  chat_id: '573012637232',
  message: 'Hello! This is a test message.'
)

if response.success?
  puts "Message sent successfully!"
  puts response.parsed_response
else
  puts "Error: #{response.code} - #{response.body}"
end
```

### Send Message with File

Send a message with an attached file:

```ruby
response = client.send_message_with_file(
  chat_id: '573012637232',
  message: 'Check out this document!',
  file_path: '/path/to/your/document.pdf'
)

if response.success?
  puts "Message with file sent successfully!"
else
  puts "Error sending file: #{response.body}"
end
```

### Send File Only

Send just a file without additional message text:

```ruby
response = client.send_file_only(
  chat_id: '573012637232',
  file_path: '/path/to/image.jpg',
  caption: 'Optional caption for the file'  # optional
)
```

### Get Session Status

Check the status of your WhatsApp IA session:

```ruby
response = client.get_session_status

if response.success?
  status = response.parsed_response
  puts "Session Status: #{status['status']}"
  puts "Connected: #{status['connected']}"
else
  puts "Error getting session status: #{response.body}"
end
```

### Get Chats

Retrieve a list of chats from your WhatsApp session:

```ruby
response = client.get_chats(
  limit: 20,    # optional, defaults to 50
  offset: 0     # optional, defaults to 0
)

if response.success?
  chats = response.parsed_response['chats']
  chats.each do |chat|
    puts "Chat: #{chat['name']} (#{chat['id']})"
  end
end
```

### Get Chat Messages

Retrieve messages from a specific chat:

```ruby
response = client.get_chat_messages(
  chat_id: '573012637232',
  limit: 30,    # optional, defaults to 50
  offset: 0     # optional, defaults to 0
)

if response.success?
  messages = response.parsed_response['messages']
  messages.each do |message|
    puts "#{message['timestamp']}: #{message['body']}"
  end
end
```

## Complete Workflow Example

```ruby
# Initialize client
client = WhatsappIa::Client.new(
  api_key: ENV['WHATSAPP_IA_API_KEY'],
  session_ia_id: ENV['WHATSAPP_IA_SESSION_ID']
)

begin
  # Check session status first
  status_response = client.get_session_status
  
  if status_response.success?
    puts "Session is active and ready"
    
    # Get list of chats
    chats_response = client.get_chats(limit: 10)
    
    if chats_response.success?
      chats = chats_response.parsed_response['chats']
      
      # Send a message to the first chat
      if chats.any?
        first_chat = chats.first
        
        # Send text message
        message_response = client.send_text_message(
          chat_id: first_chat['id'],
          message: "Hello from the WhatsApp IA Ruby client!"
        )
        
        if message_response.success?
          puts "Message sent to #{first_chat['name']}"
          
          # Send a file as follow-up
          if File.exist?('/path/to/document.pdf')
            file_response = client.send_message_with_file(
              chat_id: first_chat['id'],
              message: "Here's the document you requested:",
              file_path: '/path/to/document.pdf'
            )
            
            puts file_response.success? ? "File sent!" : "Failed to send file"
          end
        end
      end
    end
  else
    puts "Session is not active: #{status_response.body}"
  end
  
rescue => e
  puts "Error: #{e.message}"
end
```

## Error Handling

The client returns HTTParty response objects that provide:

- `response.code` - HTTP status code
- `response.parsed_response` - Parsed JSON response
- `response.success?` - Boolean success indicator (2xx status codes)
- `response.body` - Raw response body

Common error scenarios:

```ruby
response = client.send_text_message(chat_id: '123', message: 'test')

case response.code
when 200, 201
  puts "Success: #{response.parsed_response}"
when 401
  puts "Authentication failed - check your API key"
when 403
  puts "Forbidden - check your session permissions"
when 404
  puts "Chat not found"
when 429
  puts "Rate limit exceeded"
else
  puts "Unexpected error: #{response.code} - #{response.body}"
end
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `send_text_message` | `POST /api/v1/whatsapp_ia/messages` | Send text message |
| `send_message_with_file` | `POST /api/v1/whatsapp_ia/messages` | Send message with file attachment |
| `send_file_only` | `POST /api/v1/whatsapp_ia/messages` | Send file without message text |
| `get_session_status` | `GET /api/v1/whatsapp_ia/sessions/status` | Get session connection status |
| `get_chats` | `GET /api/v1/whatsapp_ia/chats` | Get list of chats |
| `get_chat_messages` | `GET /api/v1/whatsapp_ia/chats/{id}/messages` | Get messages from specific chat |

## Configuration

Set environment variables for your WhatsApp IA credentials:

```bash
export WHATSAPP_IA_API_KEY="your_api_key_here"
export WHATSAPP_IA_SESSION_ID="68ded1910b0cb4a87c7df630"
export WHATSAPP_IA_BASE_URL="https://marce.ai"  # optional
```

### Using Environment Variables

```ruby
client = WhatsappIa::Client.new(
  api_key: ENV['WHATSAPP_IA_API_KEY'],
  session_ia_id: ENV['WHATSAPP_IA_SESSION_ID'],
  base_url: ENV['WHATSAPP_IA_BASE_URL'] || 'https://marce.ai'
)
```

## File Upload Support

The client supports uploading various file types:

- **Documents**: PDF, DOC, DOCX, TXT
- **Images**: JPG, JPEG, PNG, GIF
- **Audio**: MP3, WAV, OGG
- **Video**: MP4, AVI, MOV

File size limits and supported formats depend on WhatsApp's restrictions and your IA plan.

## Logging

The client automatically logs all HTTP requests and responses using Rails logger with the following format:

```
🐚 === WHATSAPP IA CURL COMMAND ===
curl -X POST "https://marce.ai/api/v1/whatsapp_ia/messages" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "X-Session-Ia-Id: 68ded1910b0cb4a87c7df630" \
  -F "chat_id=573012637232" \
  -F "message=Hello World"

📥 === RESPONSE ===
Status: 200
Body: {"status":"success","message_id":"msg_123"}
🔚 === END ===
```

This helps with debugging and API integration testing.

## Thread Safety

Each client instance maintains its own configuration (API key, session ID, base URL). For multi-threaded applications, you can safely share client instances or create separate instances per thread as needed.

## Rate Limiting

Be aware of API rate limits imposed by the WhatsApp IA service. The client doesn't implement automatic retry logic, so you should handle rate limiting in your application:

```ruby
def send_with_retry(client, chat_id, message, max_retries: 3)
  retries = 0
  
  begin
    response = client.send_text_message(chat_id: chat_id, message: message)
    
    if response.code == 429 && retries < max_retries
      sleep_time = 2 ** retries  # Exponential backoff
      sleep(sleep_time)
      retries += 1
      retry
    end
    
    response
  rescue => e
    Rails.logger.error "WhatsApp IA send failed: #{e.message}"
    raise
  end
end
```