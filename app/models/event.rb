class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :description, type: String
  field :address, type: String
  field :date, type: Time

  has_many :assistants, dependent: :destroy

  # Indexes
  index({ title: 1 })
  index({ date: 1 })
  index({ created_at: 1 })
  index({ updated_at: 1 })
end
