module Planner
  # Implements the most basic planning system.
  # Add matches to the latest round until either the round is full
  # or there already exists a match with one of the teams.
  module SimplePlanner
    extend self

    def plan_rounds(driver, matches, field_count)
      rounds = []

      matches.each do |match|
        round = first_available_round(driver, match, rounds, field_count)
        if round.nil?
          round = []
          rounds.append(round)
        end
        round.append(match)
      end

      rounds
    end

    private

    def first_available_round(driver, match, rounds, field_count)
      rounds.each do |round|
        return round if driver.match_bye?(match)

        next if round.size >= field_count

        teams_in_round = round.map { |m| driver.get_match_teams(m) }.flatten
        teams_in_match = driver.get_match_teams(match)
        next if teams_in_round.include?(teams_in_match[0]) || teams_in_round.include?(teams_in_match[1])

        return round
      end
      nil
    end
  end
end
