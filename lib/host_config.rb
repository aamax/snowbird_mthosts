module HostConfig
  def self.season_start_date
    @season_start_date ||= SysConfig.first.season_start_date
  end

  def self.season_year
    @season_year ||= SysConfig.first.season_year
  end

  def self.group_1_year
    @group_1_year ||= SysConfig.first.group_1_year
  end

  def self.group_2_year
    @group_2_year ||= SysConfig.first.group_2_year
  end

  def self.group_3_year
    @group_3_year ||= SysConfig.first.group_3_year
  end

  def self.bingo_start_date
    @bingo_start_date ||= SysConfig.first.bingo_start_date
  end

  def self.initialize_values
    @season_start_date = nil
    @season_year = nil
    @group_1_year = nil
    @group_2_year = nil
    @group_3_year = nil
    @bingo_start_date = nil
  end
end