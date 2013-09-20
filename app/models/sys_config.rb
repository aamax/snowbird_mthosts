# == Schema Information
#
# Table name: sys_configs
#
#  id                :integer          not null, primary key
#  season_year       :integer
#  group_1_year      :integer
#  group_2_year      :integer
#  group_3_year      :integer
#  season_start_date :date
#  bingo_start_date  :date
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class SysConfig < ActiveRecord::Base
  attr_accessible :season_year, :group_1_year, :group_2_year, :group_3_year, :season_start_date, :bingo_start_date
end
