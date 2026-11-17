# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# A private installation starts empty: the teammates below exist only for the demo.
# The line goes to the terminal that runs db:seed or db:prepare, like the other messages here.
unless Rails.configuration.x.demo_mode
  puts "Demo mode is off (DEMO_MODE is not \"true\"), so no demo data was loaded." # rubocop:disable Rails/Output
  return
end

# The fictitious participants of every visitor's sample tasks (see DemoSandbox). Their passwords are random and never
# shown, so nobody can sign in as them; running the seeds again gives an existing teammate a new random password too.
User::TEAMMATE_EMAILS.each do |email|
  User.find_or_initialize_by(email:).update!(password: SecureRandom.base58(32))
end

puts "Teammates have been created" # rubocop:disable Rails/Output
