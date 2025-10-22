module Admin
  class AssistantsController < AdminApplicationController
    before_action :set_event, only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_assistant, only: [:show, :edit, :update, :destroy]

    def index
      if @event
        # Event-specific assistants with search
        @assistants = @event.assistants
        
        if params[:search].present?
          search_term = params[:search].strip
          @assistants = @assistants.any_of(
            { name: /#{Regexp.escape(search_term)}/i },
            { email: /#{Regexp.escape(search_term)}/i },
            { phone: /#{Regexp.escape(search_term)}/i },
            { open1: /#{Regexp.escape(search_term)}/i },
            { open2: /#{Regexp.escape(search_term)}/i },
            { open3: /#{Regexp.escape(search_term)}/i },
            { _attendance_status: /#{Regexp.escape(search_term)}/i }
          )
        end
        
        @assistants = @assistants.order_by(created_at: :desc)
      else
        # All assistants
        @assistants = Assistant.all.order_by(created_at: :desc)
      end
    end

    def show
    end

    def new
      @assistant = @event.assistants.build
    end

    def create
      @assistant = @event.assistants.build(assistant_params)
      
      if @assistant.save
        redirect_to admin_event_path(@event), notice: 'Assistant was successfully created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @assistant.update(assistant_params)
        redirect_to admin_event_path(@assistant.event), notice: 'Assistant was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      event = @assistant.event
      @assistant.destroy
      redirect_to admin_event_path(event), notice: 'Assistant was successfully deleted.'
    end

    def mark_attendance
      event = Event.find(params[:event_id])
      assistant = event.assistants.find(params[:assistant_id])
      
      if assistant
        assistant.mark_as_attended!
        redirect_to admin_event_path(event), 
          notice: "✅ #{assistant.name} marked as attended!"
      else
        redirect_to admin_root_path, 
          alert: "❌ Assistant not found."
      end
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to admin_root_path, 
        alert: "❌ Event or assistant not found."
    end

    def send_whatsapp_invitation
      @assistant = Assistant.find(params[:id])
      
      if @assistant.phone.blank?
        redirect_back fallback_location: admin_event_assistants_path(@assistant.event), 
          alert: "❌ #{@assistant.name} has no phone number"
        return
      end

      begin
        # Generate QR code image
        qr_image_file = @assistant.generate_qr_code_image
        
        # Prepare WhatsApp message using event description
        message = "🎉 #{@assistant.event.title}\n\n" \
                  "Hello #{@assistant.name}!\n\n" \
                  "#{@assistant.event.description || 'Event invitation'}\n\n"
        
        # Send via WhatsApp IA
        whatsapp_client = WhatsappIa::Client.new
        formatted_phone = @assistant.formatted_phone_for_whatsapp
        
        response = whatsapp_client.send_message(
          chat_id: formatted_phone,
          message: message,
          file_path: qr_image_file.path
        )
        
        if response.success?
          redirect_back fallback_location: admin_event_assistants_path(@assistant.event), 
            notice: "✅ WhatsApp invitation sent to #{@assistant.name}"
        else
          redirect_back fallback_location: admin_event_assistants_path(@assistant.event), 
            alert: "❌ Failed to send WhatsApp: #{response.body}"
        end
        
      rescue => e
        redirect_back fallback_location: admin_event_assistants_path(@assistant.event), 
          alert: "❌ Error sending WhatsApp: #{e.message}"
      ensure
        # Clean up temporary file
        qr_image_file&.close
        qr_image_file&.unlink
      end
    end

    private

    def set_event
      @event = Event.find(params[:event_id]) if params[:event_id]
    end

    def set_assistant
      @assistant = Assistant.find(params[:id])
    end

    def assistant_params
      params.require(:assistant).permit(:name, :email, :phone, :open1, :open2, :open3, :attendance_status)
    end
  end
end