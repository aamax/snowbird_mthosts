source 'http://rubygems.org'
gem 'rails', '4.2.4'
ruby '2.2.3'

gem 'sass-rails',   '~> 4.0.5'
gem 'coffee-rails', '~> 4.1.0'
gem 'uglifier', '>= 1.3.0'

gem 'bootstrap-sass', '~> 2.1.1.0'
gem 'therubyracer'

# added to make upgrade easier
gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'


gem 'jquery-rails'
gem 'jquery-ui-rails'
gem "pg", ">= 0.14.1"
gem "capybara", ">= 2.0.2", :group => :test
gem "devise", ">= 2.2.3"
gem "cancan", ">= 1.6.8"
gem "rolify", ">= 3.2.0"
gem "figaro", ">= 0.5.3"
gem "better_errors", ">= 0.6.0", :group => :development
gem "binding_of_caller", ">= 0.7.1", :group => :development, :platforms => [:mri_19, :rbx]

gem 'tinymce-rails'

gem 'bootstrap-will_paginate'
gem 'bootstrap-datepicker-rails'
gem 'bootstrap-addons-rails'

gem 'jbuilder'
gem 'awesome_print'
gem 'gravatar_image_tag', '1.0.0.pre2'
gem 'will_paginate', "~>3.0.2"
gem 'nokogiri'

gem 'ng-rails-csrf', :git => "git://github.com/xrd/ng-rails-csrf.git" #helps rails csrf with angular
gem 'angularjs-rails'  #, '~>1.2.26'

gem 'gon'

gem 'puma', ">= 3.10.0"


group :development do
  gem 'annotate', :git => 'git://github.com/ctran/annotate_models.git'
  gem "bullet"
  gem 'letter_opener'
end

group :test, :development do
  gem "ansi"
  gem 'minitest-rails'
  gem "minitest-rails-capybara"
  gem "minitest-stub-const"
  gem 'minitest-focus'
  gem 'minitest-reporters', '~> 1.1.0'
  #gem 'mini_backtrace'
  gem 'pry'
  gem "factory_girl_rails", ">= 4.2.0"

  gem "capybara-webkit"
  gem 'timecop'
end

group :production do
  gem 'rails_12factor'
end

gem 'activerecord-session_store'

gem "simple_calendar", "~> 2.0"
gem 'whenever', require: false