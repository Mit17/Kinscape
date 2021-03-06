SimpleForm.setup do |config|
  config.wrappers :default,
                  class: :input,
                  hint_class: :field_with_hint,
                  error_class: :field_with_errors do |b|
    b.use :placeholder

    b.optional :maxlength

    b.optional :pattern

    b.optional :min_max

    b.optional :readonly

    b.use :label_input
    b.use :hint,  wrap_with: { tag: :span, class: :hint }
    b.use :error, wrap_with: { tag: :span, class: :error }
  end

  config.default_wrapper = :default

  config.boolean_style = :inline

  config.button_class = 'btn'

  config.error_notification_tag = :div

  config.error_notification_class = 'error_notification'

  config.browser_validations = true

  config.boolean_label_class = 'checkbox'
end
