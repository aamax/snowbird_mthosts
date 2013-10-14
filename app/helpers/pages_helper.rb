module PagesHelper
  def home_page_message
    @page = Page.find_by_name("aamax")
    @page = Page.create(:name => 'aamax', :content => '') if @page.nil?
    @page
  end
end
