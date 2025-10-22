namespace :admin do
  desc "Create first admin user"
  task create_first_user: :environment do
    email = "admin@codieventos.com"
    password = "password123"
    name = "Administrator"

    if AdminUser.where(email: email).exists?
      puts "Admin user already exists with email: #{email}"
    else
      admin_user = AdminUser.create!(
        email: email,
        password: password,
        password_confirmation: password,
        name: name
      )
      
      puts "✅ Admin user created successfully!"
      puts "Email: #{admin_user.email}"
      puts "Password: #{password}"
      puts "Name: #{admin_user.name}"
      puts ""
      puts "You can now login at: http://localhost:3000/admin/login"
    end
  end

  desc "Reset admin user password"
  task reset_password: :environment do
    email = ENV['EMAIL'] || "admin@codieventos.com"
    new_password = ENV['PASSWORD'] || "password123"

    admin_user = AdminUser.where(email: email).first
    if admin_user
      admin_user.update!(password: new_password, password_confirmation: new_password)
      puts "✅ Password updated for #{email}"
      puts "New password: #{new_password}"
    else
      puts "❌ Admin user not found with email: #{email}"
    end
  end

end