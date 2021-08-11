module Planner
  # Implements the most basic planning system.
  # Add matches to the latest round until either the round is full
  # or there already exists a match with one of the teams.
  module SimplePlanner
    extend self

    def plan_rounds(matches, field_count)
      rounds = []

      matches.each do |match|
        round = first_available_round(match, rounds, field_count)
        if round.nil?
          round = []
          rounds.append(round)
        end
        round.append(match)
      end

      rounds
    end

    private

    def first_available_round(match, rounds, field_count)
      rounds.each do |round|
        return round if match.home_team.nil? || match.away_team.nil?

        next if round.size >= field_count

        teams_in_round = round.flatten
        next if teams_in_round.include?(match.home_team) || teams_in_round.include?(match.away_team)

        return round
      end
      nil
    end
  end
end
