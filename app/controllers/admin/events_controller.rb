require 'roo'

module Admin
  class EventsController < AdminApplicationController
    before_action :set_event, only: [:show, :edit, :update, :destroy, :upload_assistants, :remove_all_assistants]

    def index
      @events = Event.all
    end

    def show
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)
      
      if @event.save
        redirect_to admin_event_path(@event), notice: 'Event was successfully created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: 'Event was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: 'Event was successfully deleted.'
    end

    def upload_assistants
      unless params[:file].present?
        redirect_to admin_event_path(@event), alert: 'Please select a file to upload.'
        return
      end

      file = params[:file]
      
      unless file.content_type.in?(['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'])
        redirect_to admin_event_path(@event), alert: 'Please upload a valid Excel file (.xlsx or .xls).'
        return
      end

      begin
        spreadsheet = Roo::Spreadsheet.open(file.tempfile, extension: File.extname(file.original_filename))
        
        added_count = 0
        errors = []
        
        # Skip header row (row 1) and process data starting from row 2
        (2..spreadsheet.last_row).each do |row|
          name = spreadsheet.cell(row, 1)&.to_s&.strip
          email = spreadsheet.cell(row, 2)&.to_s&.strip
          phone = spreadsheet.cell(row, 3)&.to_s&.strip
          open1 = spreadsheet.cell(row, 4)&.to_s&.strip
          open2 = spreadsheet.cell(row, 5)&.to_s&.strip
          open3 = spreadsheet.cell(row, 6)&.to_s&.strip
          
          # Skip empty rows
          next if name.blank? && email.blank? && phone.blank?
          
          assistant = @event.assistants.build(
            name: name,
            email: email,
            phone: phone,
            open1: open1.present? ? open1 : nil,
            open2: open2.present? ? open2 : nil,
            open3: open3.present? ? open3 : nil
          )
          
          if assistant.save
            added_count += 1
          else
            errors << "Row #{row}: #{assistant.errors.full_messages.join(', ')}"
          end
        end
        
        if errors.any?
          flash[:alert] = "#{added_count} assistants added successfully. Errors: #{errors.join('; ')}"
        else
          flash[:notice] = "Successfully added #{added_count} assistants to the event."
        end
        
      rescue => e
        flash[:alert] = "Error processing file: #{e.message}"
      end
      
      redirect_to admin_event_path(@event)
    end

    def remove_all_assistants
      assistants_count = @event.assistants.count
      @event.assistants.destroy_all
      
      redirect_to admin_event_path(@event), notice: "Successfully removed #{assistants_count} assistants from the event."
    end

    def send_all_whatsapp_invitations
      result = WhatsappInvitationService.send_event_invitations(@event)
      
      if result[:success]
        message = "✅ Successfully sent #{result[:success_count]} WhatsApp invitations!"
        message += " #{result[:skipped_message]}" if result[:skipped_count] && result[:skipped_count] > 0
        redirect_to admin_event_assistants_path(@event), notice: message
      elsif result[:error]
        redirect_to admin_event_assistants_path(@event), alert: "❌ #{result[:error]}"
      else
        error_details = result[:errors].any? ? "\n\nErrors:\n#{result[:errors].join("\n")}" : ""
        skipped_info = result[:skipped_count] && result[:skipped_count] > 0 ? " (#{result[:skipped_message]})" : ""
        redirect_to admin_event_assistants_path(@event), 
          alert: "⚠️ Sent #{result[:success_count]} invitations, #{result[:error_count]} failed#{error_details}#{skipped_info}"
      end
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:title, :description, :address, :date)
    end
  end
end