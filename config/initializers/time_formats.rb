# frozen_string_literal: true

Time::DATE_FORMATS[:us_datetime] = ->(ts) { ts.strftime('%m/%d/%Y %l:%M%p') }
Time::DATE_FORMATS[:us_date] = ->(ts) { ts.strftime('%m/%d/%Y') }
Date::DATE_FORMATS[:us_date] = ->(d) { d.strftime('%m/%d/%Y') }