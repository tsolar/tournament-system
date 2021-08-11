module Planner
  # Implements a round planner that aims to evenly distribute
  # matches between rounds. So, instead of having one round with 3 matches and
  # another with only 1 match, this planner will create two round with 2 matches.
  module EvenDistributionPlanner
    extend self

    def plan_rounds(matches, field_count)
      effective_fields = matches_per_round(matches, field_count)

      rounds = []
      matches.each do |match|
        round = first_available_round_or_new(match, rounds, effective_fields)
        round.append(match)
      end

      rounds
    end

    private

    def matches_per_round(matches, field_count)
      match_count = non_bye_matches(matches).size
      minimum_round_count = (match_count.to_f / field_count).ceil
      (match_count.to_f / minimum_round_count).ceil
    end

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

    def first_available_round_or_new(match, rounds, field_count)
      round = first_available_round(match, rounds, field_count)
      if round.nil?
        round = []
        rounds.append(round)
      end
      round
    end

    def bye?(match)
      match.home_team.nil? || match.away_team.nil?
    end

    def non_bye_matches(matches)
      matches.reject { |m| bye?(m) }
    end
  end
end
