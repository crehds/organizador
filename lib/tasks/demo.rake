namespace :demo do
  desc "Delete all data, visitor accounts included, and reload the demo data from db/seeds.rb (demo mode only)"
  task reset: :environment do
    DemoReset.call
    puts "Demo data has been reset."
  rescue DemoReset::Disabled => e
    abort e.message
  end
end
