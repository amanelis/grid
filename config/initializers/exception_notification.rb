# Redefine these in environment specific config files as needed. But when doing so, make sure to add to the config.after_initialize block.
ExceptionNotification::Notifier.sender_address = "exception@cityvoice.com"
ExceptionNotification::Notifier.exception_recipients = %w{dev@cityvoice.com}
ExceptionNotification::Notifier.sections = %w{request session backtrace environment}
ExceptionNotification::Notifier.email_prefix = ""