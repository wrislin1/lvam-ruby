module ReportsHelper
  def report_actions(report)
    actions = []
    if policy(report).show?
      actions << {
        name: "View",
        icon: "fa-eye",
        path: report_path(report),
        turbo_frame: "_top"
      }
    end
    if policy(report).edit?
      actions << {
        name: "Edit",
        icon: "fa-edit",
        path: edit_report_path(report),
        turbo_frame: "_top"
      }
    end
    if policy(report).destroy?
      actions << {
        name: "Delete",
        icon: "fa-trash",
        path: report_path(report),
        method: :delete,
        turbo: true
      }
    end
    actions
  end

  def report_download_actions(report)
    [
      {
        name: "PDF File",
        icon: "fa-file-pdf fa-lg",
        path: download_report_path(report, type: "pdf"),
        method: :post
      },
      {
        name: "PNG Image",
        icon: "fa-file-png fa-lg",
        path: download_report_path(report, type: "png"),
        method: :post
      },
      {
        name: "JPG Image",
        icon: "fa-file-jpg fa-lg",
        path: download_report_path(report, type: "jpg"),
        method: :post
      }
    ]
  end

  def report_col_class(report)
    case report.report_columns.count
    when 1
      "lg:grid-cols-1"
    when 2
      "lg:grid-cols-2"
    when 3
      "lg:grid-cols-3"
    when 4
      "lg:grid-cols-4"
    when 5
      "lg:grid-cols-5"
    else
      ""
    end
  end
end
