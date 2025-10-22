class WhatsappInvitationService
  def self.send_invitation(assistant)
    new(assistant).send_invitation
  end

  def self.send_bulk_invitations(assistants)
    new.send_bulk_invitations(assistants)
  end

  def self.send_event_invitations(event)
    new.send_bulk_invitations(event.assistants.to_a)
  end

  def initialize(assistant = nil)
    @assistant = assistant
  end

  def send_invitation
    return { success: false, error: "Assistant has no phone number" } if @assistant.phone.blank?

    begin
      # Generate QR code image
      qr_image_file = @assistant.generate_qr_code_image
      
      # Prepare WhatsApp message using event description
      message = build_message(@assistant)
      
      # Send via WhatsApp IA
      whatsapp_client = WhatsappIa::Client.new
      formatted_phone = @assistant.formatted_phone_for_whatsapp
      
      response = whatsapp_client.send_message(
        chat_id: formatted_phone,
        message: message,
        file_path: qr_image_file.path
      )
      
      if response.success?
        { success: true, message: "WhatsApp invitation sent to #{@assistant.name}" }
      else
        { success: false, error: "Failed to send WhatsApp: #{response.body}" }
      end
      
    rescue => e
      { success: false, error: "Error sending WhatsApp: #{e.message}" }
    ensure
      # Clean up temporary file
      qr_image_file&.close
      qr_image_file&.unlink
    end
  end

  def send_bulk_invitations(assistants)
    assistants_with_phone = assistants.select { |a| a.phone.present? }
    
    return { success: false, error: "No assistants with phone numbers found" } if assistants_with_phone.empty?

    success_count = 0
    error_count = 0
    errors = []
    
    assistants_with_phone.each do |assistant|
      result = self.class.send_invitation(assistant)
      
      if result[:success]
        success_count += 1
      else
        error_count += 1
        errors << "#{assistant.name}: #{result[:error]}"
      end
      
      # Add small delay to avoid rate limiting
      sleep(1)
    end
    
    {
      success: error_count == 0,
      success_count: success_count,
      error_count: error_count,
      errors: errors
    }
  end

  private

  def build_message(assistant)
    "Hello #{assistant.name}!\n\n" \
    "#{assistant.event.description || 'Event invitation'}\n\n"
  end
end