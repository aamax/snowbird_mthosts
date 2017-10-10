namespace :data do
  task :add_trainer => :environment do
    puts "add trainer role to system"
    u = User.find_by_email('altasnow@gmail.com')
    u.add_role :trainer
  end

  task :add_surveyors => :environment do
    puts "add surveyors to system"

    # read users, add then and add role to each


    puts "done adding surveyors"
  end
end

