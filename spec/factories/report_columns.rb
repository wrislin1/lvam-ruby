FactoryBot.define do
  factory :report_column do
    report { nil }
    title { "MyString" }
    sort { 1 }
    subtitle { "MyString" }
  end
end
