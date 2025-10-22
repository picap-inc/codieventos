class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :description, type: String
  field :address, type: String
  field :date, type: Time

  has_many :assistants, dependent: :destroy
end
