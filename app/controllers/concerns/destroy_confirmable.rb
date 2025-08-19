module DestroyConfirmable
  extend ActiveSupport::Concern

  def confirm_or_destroy(record, path, method: :delete, header: nil, message: nil)
    class_name = record.class.name.humanize
    if params[:confirmed] == "true"
      if record.destroy
        render turbo_stream: [
          turbo_stream.remove(record),
          stream_success_alert("#{class_name} deleted successfully!"),
          close_confirmation_modal
        ]
      else
        render turbo_stream: [
          stream_error_alert("Unable to delete #{class_name}: #{record.errors.full_messages.join(', ')}")
        ], status: :unprocessable_entity
      end
    else
      render turbo_stream: [
        render_confirmation_modal(
          path,
          method:,
          header:,
          message:
        )
      ]
    end
  end
end
