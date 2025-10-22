#!/usr/bin/env ruby

# Example usage of WhatsApp IA Client
# This file demonstrates how to use the WhatsappIa::Client library

require_relative 'client'

# Example configuration - use environment variables in production
API_KEY = ENV['WHATSAPP_IA_API_KEY'] || 'your_api_key_here'
SESSION_ID = ENV['WHATSAPP_IA_SESSION_ID'] || '68ded1910b0cb4a87c7df630'
CHAT_ID = ENV['WHATSAPP_IA_CHAT_ID'] || '573012637232'

puts "🤖 WhatsApp IA Client Example"
puts "=" * 40

begin
  # Initialize the client
  client = WhatsappIa::Client.new(
    api_key: API_KEY,
    session_ia_id: SESSION_ID
  )
  
  puts "✅ Client initialized successfully"
  
  # Check session status
  puts "\n📡 Checking session status..."
  status_response = client.get_session_status
  
  if status_response.success?
    puts "✅ Session is active"
    puts "   Status: #{status_response.parsed_response}"
  else
    puts "❌ Session check failed: #{status_response.code}"
    puts "   Error: #{status_response.body}"
  end
  
  # Get chats list
  puts "\n💬 Getting chats list..."
  chats_response = client.get_chats(limit: 5)
  
  if chats_response.success?
    chats = chats_response.parsed_response['chats'] || []
    puts "✅ Found #{chats.length} chats"
    
    chats.each_with_index do |chat, index|
      puts "   #{index + 1}. #{chat['name']} (#{chat['id']})"
    end
  else
    puts "❌ Failed to get chats: #{chats_response.code}"
  end
  
  # Send a text message
  puts "\n📤 Sending text message..."
  message_response = client.send_text_message(
    chat_id: CHAT_ID,
    message: "Hello! This is a test message from the WhatsApp IA Ruby client. 🚀"
  )
  
  if message_response.success?
    puts "✅ Message sent successfully"
    puts "   Response: #{message_response.parsed_response}"
  else
    puts "❌ Failed to send message: #{message_response.code}"
    puts "   Error: #{message_response.body}"
  end
  
  # Example of sending a file (uncomment and provide a real file path)
  # puts "\n📎 Sending file..."
  # file_path = '/path/to/your/document.pdf'
  # 
  # if File.exist?(file_path)
  #   file_response = client.send_message_with_file(
  #     chat_id: CHAT_ID,
  #     message: "Here's the document you requested!",
  #     file_path: file_path
  #   )
  #   
  #   if file_response.success?
  #     puts "✅ File sent successfully"
  #   else
  #     puts "❌ Failed to send file: #{file_response.code}"
  #   end
  # else
  #   puts "⚠️  File not found: #{file_path}"
  # end
  
  # Get messages from a chat
  puts "\n📥 Getting chat messages..."
  messages_response = client.get_chat_messages(
    chat_id: CHAT_ID,
    limit: 3
  )
  
  if messages_response.success?
    messages = messages_response.parsed_response['messages'] || []
    puts "✅ Found #{messages.length} recent messages"
    
    messages.each_with_index do |message, index|
      puts "   #{index + 1}. [#{message['timestamp']}] #{message['body']&.truncate(50)}"
    end
  else
    puts "❌ Failed to get messages: #{messages_response.code}"
  end
  
  puts "\n🎉 Example completed successfully!"
  
rescue => e
  puts "\n💥 Error occurred: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(3).join("\n              ")}"
  
  puts "\n💡 Make sure to set the following environment variables:"
  puts "   WHATSAPP_IA_API_KEY=your_api_key"
  puts "   WHATSAPP_IA_SESSION_ID=your_session_id"
  puts "   WHATSAPP_IA_CHAT_ID=target_chat_id"
end

puts "\n" + "=" * 40
puts "Example finished"