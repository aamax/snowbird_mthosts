# == Schema Information
#
# Table name: shift_types
#
#  id          :integer          not null, primary key
#  short_name  :string(255)      not null
#  description :string(255)      not null
#  start_time  :string(255)
#  end_time    :string(255)
#  tasks       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ShiftType < ActiveRecord::Base
  attr_accessible :short_name, :description, :start_time, :end_time, :tasks

  #time_regex = /[0-1][0-9]:[0-6][0-9]/

  validates   :short_name, :presence => true, :length   => { :maximum => 20 }
  validates   :description, :presence => true, :length   => { :maximum => 255 }
  #validates   :start_time, :presence => true, :format => { :with => time_regex }
  #validates   :end_time, :presence => true, :format => { :with => time_regex }
  validates   :tasks, :length   => { :maximum => 255 }

  #has_many    :shifts, :dependent => :destroy
  #
  #default_scope :order => "shortname"
  #scope :distinctShifttypes, :select => ('distinct shortname')
  scope :meetings, -> {where("short_name ilike 'M%'").order(:short_name)}

  def self.team_lead_type
    ShiftType.where("short_name in ('TL')")
  end

  def is_tour?
    !/(P[1-4]|ST)/.match(self.short_name).nil?
    # self.tasks.nil? ? false : self.tasks.downcase.include?('tour')
  end

  def is_working?
    self.short_name[0] != 'M'
  end

  def abbreviated_name
    self.short_name[0..1]
  end

end
