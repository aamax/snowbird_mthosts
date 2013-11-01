# == Schema Information
#
# Table name: surveys
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  date       :datetime
#  count      :integer
#  type1      :integer
#  type2      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Survey < ActiveRecord::Base
  attr_accessible :date, :count, :type1, :type2, :user_id

  TYPE1_TOTAL = 38
  TYPE2_TOTAL = 0

  belongs_to :user

  def self.total_row(user)
    tot_t1 = 0
    tot_t2 = 0

    unless user.nil?
      user.surveys.each do |s|
        tot_t1 += s.type1
        tot_t2 += s.type2
      end
    end
    [user.name, tot_t1, tot_t2, "#{TYPE1_TOTAL - tot_t1} : #{TYPE2_TOTAL - tot_t2}", user.id]
  end
end
