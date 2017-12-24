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
    else
      url = "/drop_driver/#{self.id}"
      title = "title=\"drop driver\">"
      lable = "Drop"
      btn_class = "class='hauler_edit_btn btn btn-danger"
    end
    "<a href=\"#{url}\" #{btn_class}' #{title}#{lable}</a>".html_safe
  end

  def rider_not_riding(user)
    self.riders.each do |rider|
      if rider.user == user
        return false
      end
    end
    user.id != self.driver_id
  end

  def eligible_riders
    retval = []
    return retval if self.open_seat_count == 0
    rider_list = self.riders.map { |r| r.user } << self.driver
    User.all.map {|u| u }.delete_if {|u| rider_list.include?(u)}.sort {|y,x| y.name <=> x.name }
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
end
