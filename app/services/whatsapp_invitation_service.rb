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
        @assistant.update!(whatsapp_invitation_status: :sent)
        { success: true, message: "WhatsApp invitation sent to #{@assistant.name}" }
      else
        @assistant.update!(whatsapp_invitation_status: :failed)
        { success: false, error: "Failed to send WhatsApp: #{response.body}" }
      end
      
    rescue => e
      @assistant.update!(whatsapp_invitation_status: :failed) if @assistant
      { success: false, error: "Error sending WhatsApp: #{e.message}" }
    ensure
      # Clean up temporary file
      qr_image_file&.close
      qr_image_file&.unlink
    end
  end

  def send_bulk_invitations(assistants)
    # Filter assistants: must have phone and not already sent invitation
    eligible_assistants = assistants.select { |a| a.phone.present? && a.whatsapp_invitation_status == :not_sent }
    
    return { success: false, error: "No eligible assistants found (need phone number and 'not_sent' status)" } if eligible_assistants.empty?

    # Limit to 10 assistants per bulk operation
    assistants_to_send = eligible_assistants.first(10)
    
    success_count = 0
    error_count = 0
    errors = []
    skipped_count = eligible_assistants.count - assistants_to_send.count
    
    assistants_to_send.each do |assistant|
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
    
    result = {
      success: error_count == 0,
      success_count: success_count,
      error_count: error_count,
      errors: errors
    }
    
    # Add info about skipped assistants if any
    if skipped_count > 0
      result[:skipped_count] = skipped_count
      result[:skipped_message] = "#{skipped_count} additional eligible assistants will be sent in next batch"
    end
    
    result
  end

  private

  def build_message(assistant)
    "Hello #{assistant.name}!\n\n" \
    "#{assistant.event.description || 'Event invitation'}\n\n"
  end
end