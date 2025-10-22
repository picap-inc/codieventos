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
  
  # Attendance status enum
  enum :attendance_status, [:registered, :confirmed, :attended, :absent, :cancelled], { default: :registered, required: false }
  
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }, allow_blank: true
  validates :phone, uniqueness: { scope: :event, message: "already exists for this event" }, allow_blank: true

  # Indexes
  index({ event_id: 1 })
  index({ email: 1 })
  index({ phone: 1, event_id: 1 })
  index({ name: 1 })
  index({ created_at: 1 })
  index({ _attendance_status: 1 })
  index({ _attendance_status: 1, event_id: 1 })

  def generate_qr_url(host = nil)
    if host
      "http://#{host}/admin/attendance/#{event.id}/#{id}"
    else
      # Use Rails URL helpers with configured defaults
      url_options = Rails.application.routes.default_url_options.dup
      url_options[:host] ||= 'localhost:3000'
      url_options[:protocol] ||= 'http'
      "#{url_options[:protocol]}://#{url_options[:host]}/admin/attendance/#{event.id}/#{id}"
    end
  end

  def generate_qr_code_image(host = nil)
    qr_url = generate_qr_url(host)
    qr = RQRCode::QRCode.new(qr_url)
    
    # Generate PNG image
    png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 300
    )
    
    # Save to temporary file
    temp_file = Tempfile.new(['qr_code', '.png'])
    temp_file.binmode
    temp_file.write(png.to_s)
    temp_file.rewind
    temp_file
  end

  def mark_as_attended!
    update!(attendance_status: :attended)
  end

  def formatted_phone_for_whatsapp
    return nil if phone.blank?
    
    # Remove any non-digit characters
    clean_phone = phone.gsub(/\D/, '')
    
    # If it's exactly 10 digits, add Colombia country code (57)
    if clean_phone.length == 10
      "57#{clean_phone}"
    else
      # If it already has country code or is in different format, use as is
      clean_phone
    end
  end
end
