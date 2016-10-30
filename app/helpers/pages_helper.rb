# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module PagesHelper
  def home_page_message
    @page = Page.find_by_name("aamax")
    @page = Page.create(:name => 'aamax', :content => '') if @page.nil?
    @page
  end
end
