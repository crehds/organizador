namespace :users do
  desc "Create a user with a random password, printed once: bin/rails users:create EMAIL=someone@example.com"
  task create: :environment do
    password = SecureRandom.alphanumeric(16)
    user = User.new(email: ENV.fetch("EMAIL", nil), password:)
    unless user.save
      # The app speaks Spanish; this operator command speaks English, so its errors follow.
      messages = I18n.with_locale(:en) { user.errors.full_messages.to_sentence }
      abort "Could not create the user: #{messages}. " \
            "Usage: bin/rails users:create EMAIL=someone@example.com"
    end

    puts "Created #{user.email}"
    puts "Password: #{password}"
    puts "It is shown only this once."
    # Demo mode locks the account page, so the hint would be false there.
    puts "After signing in, the user can change it at /users/edit." unless Rails.configuration.x.demo_mode
  end
end
