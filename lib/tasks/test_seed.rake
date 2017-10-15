namespace :db do
  namespace :test do
    task :load => :environment do
      puts "loading seed data for tests..."
      @sys_config = SysConfig.create(season_year: 2013, group_1_year: 2005, group_2_year: 2009, group_3_year: 2012,
                       season_start_date: Date.new(2013,9,1), bingo_start_date: Date.today())

      puts User.all.count

      @rookie_user = FactoryGirl.create(:user, name: 'rookie', start_year: 2013, active_user: true, confirmed: true)
      @rookie2 = FactoryGirl.create(:user, name: 'rookie2', start_year: 2013, active_user: true, confirmed: true)
      @rookie3 = FactoryGirl.create(:user, name: 'rookie3', start_year: 2013, active_user: true, confirmed: true)

      puts User.all.count

      @group1_user = FactoryGirl.create(:user, name: 'g3', start_year: 2012, active_user: true, confirmed: true)
      @group2_user = FactoryGirl.create(:user, name: 'g2', start_year: 2009, active_user: true, confirmed: true)
      @group3_user = FactoryGirl.create(:user, name: 'g1', start_year: 2005, active_user: true, confirmed: true)
      @team_leader = FactoryGirl.create(:user, name: 'teamlead', start_year: 2005 , active_user: true, confirmed: true)
      @team_leader.add_role :team_leader

      puts User.all.count

      User.all.each do |u|
        puts u.name
      end

      @tl = FactoryGirl.create(:shift_type, short_name: 'TL')
      @sh = FactoryGirl.create(:shift_type, short_name: 'SH')
      @p1 = FactoryGirl.create(:shift_type, short_name: 'P1')
      @p2 = FactoryGirl.create(:shift_type, short_name: 'P2')
      @p3 = FactoryGirl.create(:shift_type, short_name: 'P3')
      @p4 = FactoryGirl.create(:shift_type, short_name: 'P4')
      @g1 = FactoryGirl.create(:shift_type, short_name: 'G1weekend')
      @g2 = FactoryGirl.create(:shift_type, short_name: 'G2weekend')
      @g3 = FactoryGirl.create(:shift_type, short_name: 'G3weekend')
      @g4 = FactoryGirl.create(:shift_type, short_name: 'G4weekend')
      @g1f = FactoryGirl.create(:shift_type, short_name: 'G1friday')
      @g2f = FactoryGirl.create(:shift_type, short_name: 'G2friday')
      @g3f = FactoryGirl.create(:shift_type, short_name: 'G3friday')
      @g4f = FactoryGirl.create(:shift_type, short_name: 'G4friday')
      @c1 = FactoryGirl.create(:shift_type, short_name: 'C1weekend')
      @c2 = FactoryGirl.create(:shift_type, short_name: 'C2weekend')
      @c3 = FactoryGirl.create(:shift_type, short_name: 'C3weekend')
      @c4 = FactoryGirl.create(:shift_type, short_name: 'C4weekend')

      @start_date = (Date.today()  + 20.days)
      curr_date = @start_date - 1.day
      (0..24).each do |d|
        curr_date += 1.day

        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @p1.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @p2.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @p3.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @p4.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g1.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g2.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g3.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g4.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g1f.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g2f.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g3f.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @g4f.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @c3.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @c4.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @c1.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @c2.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @tl.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @sh.id)
        FactoryGirl.create(:shift, shift_date: curr_date, shift_type_id: @sh.id)
      end
    end
  end
end