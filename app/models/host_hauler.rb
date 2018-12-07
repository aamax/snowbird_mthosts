# == Schema Information
#
# Table name: host_haulers
#
#  id         :integer          not null, primary key
#  driver_id  :integer
#  haul_date  :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class HostHauler < ActiveRecord::Base
  has_many :riders
  has_many :users, through: :riders

  def self.add_hauler(date_value, driver_id = nil)
    hauler = HostHauler.create(haul_date: date_value, driver_id: driver_id)
    (1..13).each do |number|
      Rider.create(host_hauler_id: hauler.id)
    end
    hauler
  end

  def driver
    User.find_by(id: driver_id)
  end

  def driver_admin_button(current_user)
    return "" unless current_user.has_role? :driver

    if driver_id.nil?
      url = "/select_driver/#{self.id}"
      title = "title=\"set driver\">"
      lable = "Select"
      btn_class = "class='hauler_edit_btn btn btn-primary"
      confirmstr = ''
    else
      url = "/drop_driver/#{self.id}"
      title = "title=\"drop driver\">"
      lable = "Drop"
      btn_class = "class='hauler_edit_btn btn btn-danger"
      confirmstr = 'onclick="return confirm(\'Are you sure?\')"'
    end
    "<a #{confirmstr} href=\"#{url}\" #{btn_class}' #{title}#{lable}</a>".html_safe
  end

  def rider_not_riding(user)
    self.riders.includes(:user).each do |rider|
      if rider.user == user
        return false
      end
    end
    user.id != self.driver_id
  end

  def eligible_riders
    retval = []
    return retval if self.open_seat_count == 0

    rider_list = self.riders.includes(:user).map { |r| r.user } << self.driver

    # binding.pry


    User.active_users.map {|u| u }.delete_if {|u| rider_list.include?(u)}.sort {|y,x| y.name <=> x.name }
  end

  def eligible_drivers
    User.with_role(:driver).map { |u| u }.sort {|y,x| y.name <=> x.name }
  end

  def open_seat_count
    self.riders.map { |r| r.user_id }.delete_if { |u| !u.nil? }.count
  end

  def has_riders?
    self.riders.count != open_seat_count
  end

  def self.btn_color(hauler_id, user)
    hauler = HostHauler.includes(:riders).find_by(id: hauler_id)
    btn_color = 'btn-danger'
    if (hauler.open_seat_count != 0) && !hauler.driver_id.nil?
      btn_color = 'btn-success'
    elsif hauler.driver_id.nil?
        btn_color = 'btn-warning'
    end
    if !hauler.rider_not_riding(user) || (hauler.driver_id == user.id)
      btn_color = 'btn-primary'
    end
    btn_color
  end

  def remove_empty_seat
    return if self.open_seat_count == 0
    self.riders.each do |seat|
      if seat.user_id.nil?
        seat.delete
        return true
      end
    end
  end
end
