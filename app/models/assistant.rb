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
    qr_png = qr.as_png(
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
    
    # Load company logo
    logo_path = Rails.root.join('app', 'assets', 'images', 'codi_logo_color.png')
    if File.exist?(logo_path)
      # Create corporate QR code with logo overlay
      qr_image = ChunkyPNG::Image.from_blob(qr_png.to_s)
      logo_image = ChunkyPNG::Image.from_file(logo_path)
      
      # Calculate logo size maintaining aspect ratio (max 20% of QR code size)
      max_logo_size = (qr_image.width * 0.2).to_i
      original_width = logo_image.width
      original_height = logo_image.height
      
      # Calculate scale factor to fit within max size while maintaining aspect ratio
      scale_factor = [max_logo_size.to_f / original_width, max_logo_size.to_f / original_height].min
      new_width = (original_width * scale_factor).to_i
      new_height = (original_height * scale_factor).to_i
      
      # Calculate center position for logo
      logo_x = (qr_image.width - new_width) / 2
      logo_y = (qr_image.height - new_height) / 2
      
      # Resize logo maintaining aspect ratio
      resized_logo = logo_image.resize(new_width, new_height)
      
      # Create white background for logo
      white_bg = ChunkyPNG::Image.new(new_width + 10, new_height + 10, ChunkyPNG::Color::WHITE)
      white_bg.compose!(resized_logo, 5, 5)
      
      # Overlay logo with white background on QR code
      qr_image.compose!(white_bg, logo_x - 5, logo_y - 5)
      
      final_png = qr_image.to_blob
    else
      final_png = qr_png.to_s
    end
    
    # Save to temporary file
    temp_file = Tempfile.new(['qr_code', '.png'])
    temp_file.binmode
    temp_file.write(final_png)
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
