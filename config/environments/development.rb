Mthost::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # ActionMailer Config
  config.after_initialize do
    config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    config.action_mailer.delivery_method = :smtp
    # change to true to allow email to be sent during development
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.default :charset => "utf-8"

    config.action_mailer.smtp_settings = {
        :address        => 'smtp.gmail.com',
        :port           => '587',
        :authentication => :plain,
        :user_name => ENV["GMAIL_USERNAME"],
        :password => ENV["GMAIL_PASSWORD"],
        :domain         => 'localhost',
        :enable_starttls_auto => true
    }
  end

  config.paperclip_defaults = {
      :storage => :s3,
      :url => ':s3_domain_url',
      :path => "/:class/:attachment/:id_partition/:style/:filename",
      :s3_credentials => {
          :bucket => 'snowbirdhostgallery', #ENV['AWS_HOST_BUCKET_NAME'],
          :bucket_name => ENV['AWS_HOST_BUCKET_NAME'],
          :access_key_id => ENV['AWS_HOST_ACCESS_KEY'],
          :secret_access_key => ENV['AWS_HOST_SECRET_ACCESS_KEY']
      }
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
end

HOST_SENDER = "snowbirdhosts@gmail.com"