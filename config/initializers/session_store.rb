# Persist the honor-system login. Without an explicit expiry the session is a
# browser "session cookie" with no Max-Age, which mobile browsers purge on
# backgrounding/close — logging players out constantly. A long lifetime keeps
# them stamped into the pool until they tap "Leave".
Rails.application.config.session_store :cookie_store,
  key: "_quiniela_session",
  expire_after: 1.year,
  same_site: :lax
