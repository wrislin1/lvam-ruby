module UserDownloadHelper
  def self.column_defs
    [
      Column.new(:id, label: "ID", icon: "fa-hashtag", toggleable: false),
      Column.new(:status, icon: "fa-circle-check", template: "status"),
      Column.new(:progress_message, label: "Progress", icon: "fa-message"),
      Column.new(:error_message, label: "Error", icon: "fa-triangle-exclamation", classes: "max-w-[300px] whitespace-normal break-all"),
      Column.new(:description, label: "Report"),
      *TableHelper.updated_created_cols,
      Column.new(:actions, label: "", template: "actions", toggleable: false, sortable: false),
    ].freeze
  end
end
