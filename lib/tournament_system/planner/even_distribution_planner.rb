module Planner
  # Implements a round planner that aims to evenly distribute
  # matches between rounds. So, instead of having one round with 3 matches and
  # another with only 1 match, this planner will create two round with 2 matches.
  module EvenDistributionPlanner
    extend self

    def plan_rounds(driver, matches, field_count)
      effective_fields = matches_per_round(driver, matches, field_count)

      rounds = []
      matches.each do |match|
        round = first_available_round_or_new(driver, match, rounds, effective_fields)
        round.append(match)
      end

      rounds
    end

    private

    def matches_per_round(driver, matches, field_count)
      match_count = non_bye_matches(driver, matches).size
      minimum_round_count = (match_count.to_f / field_count).ceil
      (match_count.to_f / minimum_round_count).ceil
    end

    def first_available_round(driver, match, rounds, field_count)
      rounds.each do |round|
        return round if driver.match_bye?(match)

        next if round.size >= field_count

        teams_in_round = round.flatten
        teams_in_match = driver.get_match_teams(match)
        next if teams_in_round.include?(teams_in_match[0]) || teams_in_round.include?(teams_in_match[1])

        return round
      end
      nil
    end

    def first_available_round_or_new(driver, match, rounds, field_count)
      round = first_available_round(driver, match, rounds, field_count)
      if round.nil?
        round = []
        rounds.append(round)
      end
      round
    end

    def non_bye_matches(driver, matches)
      matches.reject { |m| driver.match_bye?(m) }
    end
  end
end
