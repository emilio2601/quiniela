module ApplicationHelper
  SITE_NAME = "La Quiniela".freeze
  DEFAULT_TITLE = "La Quiniela — World Cup 2026 Prediction Pool".freeze
  DEFAULT_DESCRIPTION =
    "A World Cup 2026 prediction pool for a handful of friends. Call every match " \
    "home, draw or away — your points are the number of people you beat, so the " \
    "upset nobody else saw pays out biggest.".freeze

  def page_title
    content_for(:title).presence || DEFAULT_TITLE
  end

  def page_description
    content_for(:description).presence || DEFAULT_DESCRIPTION
  end
end
