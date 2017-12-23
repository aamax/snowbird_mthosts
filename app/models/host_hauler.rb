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
    return "" unless current_user.admin?
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
    true
  end
end
