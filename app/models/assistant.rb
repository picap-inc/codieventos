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
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }
  validates :phone, presence: true
end
