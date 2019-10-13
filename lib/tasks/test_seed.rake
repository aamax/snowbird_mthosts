namespace :db do
  namespace :test do
    task :load => :environment do
      puts "loading seed data for tests..."
      @sys_config = SysConfig.create(season_year: 2013, group_1_year: 2005, group_2_year: 2009, group_3_year: 2012,
                       season_start_date: Date.new(2013,9,1), bingo_start_date: Date.today())

      puts User.all.count

      @rookie_user = FactoryBot.create(:user, name: 'rookie', start_year: 2013, active_user: true, confirmed: true)
      @rookie2 = FactoryBot.create(:user, name: 'rookie2', start_year: 2013, active_user: true, confirmed: true)
      @rookie3 = FactoryBot.create(:user, name: 'rookie3', start_year: 2013, active_user: true, confirmed: true)

      puts User.all.count

      @group1_user = FactoryBot.create(:user, name: 'g3', start_year: 2012, active_user: true, confirmed: true)
      @group2_user = FactoryBot.create(:user, name: 'g2', start_year: 2009, active_user: true, confirmed: true)
      @group3_user = FactoryBot.create(:user, name: 'g1', start_year: 2005, active_user: true, confirmed: true)
      @team_leader = FactoryBot.create(:user, name: 'teamlead', start_year: 2005 , active_user: true, confirmed: true)
      @team_leader.add_role :team_leader

      @surveyor = FactoryBot.create(:user, name: 'surveyor', start_year: 2005 , active_user: true, confirmed: true)
      @surveyor.add_role :surveyor

      @trainer = FactoryBot.create(:user, name: 'trainer', start_year: 2005 , active_user: true, confirmed: true)
      @trainer.add_role :trainer

      puts User.all.count

      User.all.each do |u|
        puts u.name
      end

      @tl = FactoryBot.create(:shift_type, short_name: 'TL')
      @sv = FactoryBot.create(:shift_type, short_name: 'SV')
      @tr = FactoryBot.create(:shift_type, short_name: 'TR')
      @sh = FactoryBot.create(:shift_type, short_name: 'SH')
      @p1 = FactoryBot.create(:shift_type, short_name: 'P1')
      @p2 = FactoryBot.create(:shift_type, short_name: 'P2')
      @p3 = FactoryBot.create(:shift_type, short_name: 'P3')
      @p4 = FactoryBot.create(:shift_type, short_name: 'P4')
      @g1 = FactoryBot.create(:shift_type, short_name: 'G1weekend')
      @g2 = FactoryBot.create(:shift_type, short_name: 'G2weekend')
      @g3 = FactoryBot.create(:shift_type, short_name: 'G3weekend')
      @g4 = FactoryBot.create(:shift_type, short_name: 'G4weekend')
      @g1f = FactoryBot.create(:shift_type, short_name: 'G1friday')
      @g2f = FactoryBot.create(:shift_type, short_name: 'G2friday')
      @g3f = FactoryBot.create(:shift_type, short_name: 'G3friday')
      @g4f = FactoryBot.create(:shift_type, short_name: 'G4friday')
      @c1 = FactoryBot.create(:shift_type, short_name: 'C1weekend')
      @c2 = FactoryBot.create(:shift_type, short_name: 'C2weekend')
      @c3 = FactoryBot.create(:shift_type, short_name: 'C3weekend')
      @c4 = FactoryBot.create(:shift_type, short_name: 'C4weekend')
      @m1 = FactoryBot.create(:shift_type, short_name: 'M1')
      @m2 = FactoryBot.create(:shift_type, short_name: 'M2')
      @m3 = FactoryBot.create(:shift_type, short_name: 'M3')
      @m4 = FactoryBot.create(:shift_type, short_name: 'M4')

      @start_date = (Date.today()  + 20.days)
      curr_date = @start_date - 1.day
      (0..24).each do |d|
        curr_date += 1.day

        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p1.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p2.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p3.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p4.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g1.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g2.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g3.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g4.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g1f.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g2f.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g3f.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g4f.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c3.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c4.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c1.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c2.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @tl.id)
      end

      User.populate_meetings
    end
  end
end