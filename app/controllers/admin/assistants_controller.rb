module Admin
  class AssistantsController < AdminApplicationController
    before_action :set_event, only: [:new, :create, :edit, :update, :destroy]
    before_action :set_assistant, only: [:show, :edit, :update, :destroy]

    def index
      @assistants = Assistant.all
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

    private

    def set_event
      @event = Event.find(params[:event_id]) if params[:event_id]
    end

    def set_assistant
      @assistant = Assistant.find(params[:id])
    end

    def assistant_params
      params.require(:assistant).permit(:name, :email, :phone)
    end
  end
end