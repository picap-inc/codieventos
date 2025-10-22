class AdminUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  field :email, type: String
  field :password_digest, type: String
  field :name, type: String

  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  # Indexes
  index({ email: 1 }, { unique: true })

  def self.authenticate(email, password)
    user = where(email: email.downcase).first
    user&.authenticate(password)
  end
end