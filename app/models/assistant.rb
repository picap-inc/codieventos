class Assistant
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :open1, type: String
  field :open2, type: String
  field :open3, type: String

  belongs_to :event
  
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }, allow_blank: true
  validates :phone, uniqueness: { scope: :event, message: "already exists for this event" }, allow_blank: true

  # Indexes
  index({ event_id: 1 })
  index({ email: 1 })
  index({ phone: 1, event_id: 1 })
  index({ name: 1 })
  index({ created_at: 1 })
end
