# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  street                 :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  zip                    :string(255)
#  home_phone             :string(255)
#  cell_phone             :string(255)
#  alt_email              :string(255)
#  start_year             :integer
#  notes                  :text
#  confirmed              :boolean
#  active_user            :boolean
#  nickname               :string(255)
#  snowbird_start_year    :integer
#  head_shot              :string(255)
#

require "test_helper"

class UserTest < ActiveSupport::TestCase
  before do
    @sys_config = SysConfig.first

    @rookie_user = User.find_by_name('rookie')
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @team_leader = User.find_by_name('teamlead')
    @trainer = User.find_by_name('trainer')
    @user = User.create(name: 'test user', email: 'user@example.com',
                        password: 'password')

    User.create(name: 'work user 1', email: 'email4@example.com',
                             password: 'password')
    User.create(name: 'work user 2', email: 'email5@example.com',
                             password: 'password')

    @a1 = ShiftType.find_by_short_name('A1')

    @tl = ShiftType.find_by_short_name('TL')

    @p1 = ShiftType.find_by_short_name('P1weekend')
    @p2 = ShiftType.find_by_short_name('P2weekend')
    @p3 = ShiftType.find_by_short_name('P3weekend')
    @p4 = ShiftType.find_by_short_name('P4weekend')

    @g1 = ShiftType.find_by_short_name('G1weekend')
    @g2 = ShiftType.find_by_short_name('G2weekend')
    @g3 = ShiftType.find_by_short_name('G3weekend')
    @g4 = ShiftType.find_by_short_name('G4weekend')

    @c1 = ShiftType.find_by_short_name('C1weekend')
    @c2 = ShiftType.find_by_short_name('C2weekend')

    @start_date = (Date.today()  + 20.days)
  end


  describe "seniority" do
    # it "should be Supervisor for John Cotter" do
    #   @user.name = 'John Cotter'
    #   @user.seniority.must_equal 'Supervisor'
    # end

    it 'should be Rookie for rookie user' do
      @rookie_user.seniority.must_equal 'Rookie'
    end

    it 'should be Group 3 (Newer) for first year user' do
      @group3_user.seniority.must_equal 'Group 3 (Newer)'
    end

    it 'should be Group 2 (Middle) for middle group users' do
      @group2_user.seniority.must_equal 'Group 2 (Middle)'
    end

    it 'should be Group 1 (Senior) for senior user' do
      @group1_user.seniority.must_equal 'Group 1 (Senior)'
    end
  end

  describe 'seniority Group' do
    it "should return correct group values for each user" do
      @user.active_user = false
      @user.seniority_group.must_equal 5

      @group1_user.seniority_group.must_equal 1
      @group2_user.seniority_group.must_equal 2
      @group3_user.seniority_group.must_equal 3
      @rookie_user.seniority_group.must_equal 4
    end
  end

  # describe 'trainer/trainee validation' do
  #   it 'should list all trainer shifts for user' do
  #     trainer_user = User.create(email: 'test1@test.com', password: 'password')
  #     trainee_user1 = User.create(email: 'trainee1@example.com', password: 'password')
  #     trainee_user2 = User.create(email: 'trainee2@example.com', password: 'password')
  #     trainee_user3 = User.create(email: 'trainee3@example.com', password: 'password')
  #
  #
  #     (1..9).each do |day|
  #       obj = TrainingDate.create(shift_date: "2020-01-0#{day}")
  #       obj.save
  #
  #       obj.ongoing_trainings << OngoingTraining.create(user: trainee_user1, is_trainer: false)
  #       obj.ongoing_trainings << OngoingTraining.create(user: trainee_user2, is_trainer: false)
  #       obj.ongoing_trainings << OngoingTraining.create(user: trainee_user3, is_trainer: false)
  #       obj.ongoing_trainings << OngoingTraining.create(user: trainer_user, is_trainer: true)
  #     end
  #
  #     assert_equal 9, trainee_user1.training_dates.count
  #     assert_equal 9, trainee_user2.training_dates.count
  #     assert_equal 9, trainee_user3.training_dates.count
  #
  #     assert_equal 9, trainer_user.training_dates.count
  #
  #     TrainingDate.all.each do |obj|
  #       assert_equal 1, obj.trainers.count
  #       assert_equal 3, obj.trainees.count
  #     end
  #   end
  #
  #   it 'should list ongoing trainings in the working shifts list' do
  #     trainer_user = User.create(email: 'test1@test.com', password: 'password')
  #     trainer_user.add_role :ongoing_trainer
  #     trainee_user = User.create(email: 'trainee1@example.com', password: 'password')
  #     obj = TrainingDate.create(shift_date: "#{Date.today.year}-01-01")
  #
  #     trainer_shift = OngoingTraining.create(user: trainer_user, is_trainer: true)
  #     trainee_shift = OngoingTraining.create(user: trainee_user, is_trainer: false)
  #     obj.ongoing_trainings << trainee_shift
  #     obj.ongoing_trainings << trainer_shift
  #
  #     trainer_shifts = trainer_user.get_working_shifts
  #     trainee_shifts = trainee_user.get_working_shifts
  #     assert trainer_shifts.include? trainer_shift
  #     assert trainee_shifts.include? trainee_shift
  #   end
  # end

  describe 'emails for date' do
    before do
      @user1 = User.find_by(email: 'email4@example.com')
      @user2 = User.find_by(email: 'email5@example.com')
      # @trainer = User.find_by(email: 'email8@example.com')
      # @trainer.add_role :ongoing_trainer
      #
      # @training_date = TrainingDate.create(shift_date: Date.today)
    end

    it 'should get emails for regular shifts' do
      ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today)
      @user1.shifts << ashift
      ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today)
      @user2.shifts << ashift
      # ashift = FactoryBot.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today)
      # @trainer.shifts << ashift
      emails = User.get_host_emails_for_date(Date.today).split(',')

      assert_equal 2, emails.count
      assert_includes emails, @user1.email
      assert_includes emails, @user2.email
      # assert_includes emails, @trainer.email
    end

    it 'should NOT get emails if shift is disabled' do
      ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today)
      @user1.shifts << ashift
      ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today, :disabled => true)
      @user2.shifts << ashift
      emails = User.get_host_emails_for_date(Date.today).split(',')

      assert_equal 1, emails.count
      assert_includes emails, @user1.email
    end

    # it 'should get emails for ongoing training shifts' do
    #   FactoryBot.create(:ongoing_training,
    #                     training_date_id: @training_date.id,
    #                     user_id: @user1.id,
    #                     is_trainer: false)
    #   FactoryBot.create(:ongoing_training,
    #                     training_date_id: @training_date.id,
    #                     user_id: @user2.id,
    #                     is_trainer: false)
    #   FactoryBot.create(:ongoing_training,
    #                     training_date_id: @training_date.id,
    #                     user_id: @trainer.id,
    #                     is_trainer: true)
    #   emails = User.get_host_emails_for_date(Date.today).split(',')
    #
    #   assert_equal 3, emails.count
    #   assert_includes emails, @user1.email
    #   assert_includes emails, @user2.email
    #   assert_includes emails, @trainer.email
    # end

    # it 'should get emails for mix of shifts and trainings' do
    #   ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today)
    #   @user1.shifts << ashift
    #   ashift = FactoryBot.create(:shift, :shift_type_id => @a1.id, :shift_date => Date.today)
    #   @user2.shifts << ashift
    #
    #   ashift = FactoryBot.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today)
    #   @trainer.shifts << ashift
    #   FactoryBot.create(:ongoing_training,
    #                     training_date_id: @training_date.id,
    #                     user_id: @group2_user.id,
    #                     is_trainer: false)
    #   FactoryBot.create(:ongoing_training,
    #                     training_date_id: @training_date.id,
    #                     user_id: @group3_user.id,
    #                     is_trainer: true)
    #
    #   emails = User.get_host_emails_for_date(Date.today).split(',')
    #
    #   assert_equal 5, emails.count
    #   assert_includes emails, @user1.email
    #   assert_includes emails, @user2.email
    #   assert_includes emails, @trainer.email
    #   assert_includes emails, @group2_user.email
    #   assert_includes emails, @group3_user.email
    # end
  end









  # describe 'can select ongoing trainings' do
  #   before do
  #     @training_date = TrainingDate.create(shift_date: Date.today)
  #   end
  #
  #   it 'cannot select training if rookie' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: nil,
  #                       is_trainer: false)
  #     assert_equal false, @rookie_user.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'cannot select shift if none available (unselected)' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: @user.id,
  #                       is_trainer: false)
  #     assert_equal false, @group1_user.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'cannot select shift if already working' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: @user.id,
  #                       is_trainer: false)
  #     ashift = FactoryBot.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today)
  #     @user.shifts << ashift
  #     assert_equal false, @user.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'cannot select if already have a training shift' do
  #     dt = Date.today + 1.day
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: @user.id,
  #                       is_trainer: false)
  #     @user.start_year = Date.today.year
  #     assert_equal false, @user.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'can select if non-trainer shift' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: nil,
  #                       is_trainer: false)
  #     @group1_user.start_year = Date.today.year - 1
  #     assert_equal true, @group1_user.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'can select if trainer and trainer shift' do
  #     dt = Date.today
  #     @trainer = User.find_by(email: 'email8@example.com')
  #     @trainer.add_role :ongoing_trainer
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: nil,
  #                       is_trainer: true)
  #     assert_equal true, @trainer.can_select_ongoing_training(dt)
  #   end
  #
  #   it 'cannot select if non-trainer and trainer shift' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: nil,
  #                       is_trainer: true)
  #     @user.start_year = Date.today.year
  #
  #     assert_equal false, @user.can_select_ongoing_training(dt)
  #   end
  # end
  #
  # describe 'ongoing trainings display' do
  #   before do
  #     @training_date = TrainingDate.create(shift_date: Date.today)
  #     @last_year_date = TrainingDate.create(shift_date: OGOMT_FAKE_DATE)
  #   end
  #
  #   it 'displays symbol for last year credit' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @last_year_date.id,
  #                       user_id: @user.id,
  #                       is_trainer: false)
  #     assert_equal 'LY Credit', @user.ongoing_training_display
  #   end
  #
  #   it 'displays symbol for this years scheduled training' do
  #     dt = Date.today
  #     FactoryBot.create(:ongoing_training,
  #                       training_date_id: @training_date.id,
  #                       user_id: @user.id,
  #                       is_trainer: false)
  #     assert_equal 'TY', @user.ongoing_training_display
  #   end
  #
  #   it 'blank if none scheduled' do
  #     assert_equal '', @user.ongoing_training_display
  #   end
  #
  #   it 'shows "rookie" if the user is a rookie' do
  #       assert_equal 'rookie', @rookie_user.ongoing_training_display
  #   end
  # end
end
