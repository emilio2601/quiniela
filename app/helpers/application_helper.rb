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

  # A top-bar nav link that marks itself active on the current page.
  def nav_link(label, path)
    active = current_page?(path)
    link_to label, path,
            class: "ql-navlink#{' is-active' if active}",
            aria: { current: ("page" if active) }
  end
end
