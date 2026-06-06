module MatchesHelper
  # FIFA three-letter codes for the 48 World Cup 2026 nations. Used for the
  # compact match chips/cards. Unknown names (e.g. unresolved knockout
  # placeholders like "W97") fall back to an upcased, trimmed label.
  TEAM_CODES = {
    "Algeria" => "ALG", "Argentina" => "ARG", "Australia" => "AUS", "Austria" => "AUT",
    "Belgium" => "BEL", "Bosnia & Herzegovina" => "BIH", "Brazil" => "BRA", "Canada" => "CAN",
    "Cape Verde" => "CPV", "Colombia" => "COL", "Croatia" => "CRO", "Curaçao" => "CUW",
    "Czech Republic" => "CZE", "DR Congo" => "COD", "Ecuador" => "ECU", "Egypt" => "EGY",
    "England" => "ENG", "France" => "FRA", "Germany" => "GER", "Ghana" => "GHA",
    "Haiti" => "HAI", "Iran" => "IRN", "Iraq" => "IRQ", "Ivory Coast" => "CIV",
    "Japan" => "JPN", "Jordan" => "JOR", "Mexico" => "MEX", "Morocco" => "MAR",
    "Netherlands" => "NED", "New Zealand" => "NZL", "Norway" => "NOR", "Panama" => "PAN",
    "Paraguay" => "PAR", "Portugal" => "POR", "Qatar" => "QAT", "Saudi Arabia" => "KSA",
    "Scotland" => "SCO", "Senegal" => "SEN", "South Africa" => "RSA", "South Korea" => "KOR",
    "Spain" => "ESP", "Sweden" => "SWE", "Switzerland" => "SUI", "Tunisia" => "TUN",
    "Turkey" => "TUR", "USA" => "USA", "Uruguay" => "URU", "Uzbekistan" => "UZB"
  }.freeze

  def team_code(name)
    TEAM_CODES[name] || name.to_s.upcase[0, 4]
  end
end
