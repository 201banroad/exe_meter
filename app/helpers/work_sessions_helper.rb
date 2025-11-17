# app/helpers/work_sessions_helper.rb
module WorkSessionsHelper
  def format_duration(seconds)
    s = seconds.to_i
    h = s / 3600
    m = (s % 3600) / 60
    sec = s % 60
    format("%02d:%02d:%02d", h, m, sec)
  end
end
