namespace :data do
  task :add_trainer => :environment do
    puts "add trainer role to system"
    u = User.find_by_email('altasnow@gmail.com')
    u.add_role :trainer
  end
end

