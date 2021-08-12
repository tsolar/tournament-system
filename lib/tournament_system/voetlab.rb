require 'tournament_system/algorithm/swiss'
require 'tournament_system/swiss/dutch'
require 'tournament_system/swiss/accelerated_dutch'

module TournamentSystem
  # Robust implementation of the swiss tournament system
  module Voetlab
    extend self

    # Generate matches with the given driver.
    #
    # @param driver [Driver]
    # @option options [Pairer] pairer the pairing system to use, defaults to
    #                                 {Dutch}
    # @option options [Hash] pair_options options for the chosen pairing system,
    #                                     see {Dutch} for more details
    # @return [nil]
    def generate(driver, _options = {}) # rubocop:disable Metrics/MethodLength
      driver = VoetlabDriverProxy.new(driver)

      teams = Algorithm::Util.padd_teams_even(driver.ranked_teams)

      all_matches = all_matches(driver).to_a
      rounds = match_teams(driver, teams).lazy.select do |round|
        remaining_matches = all_matches - round
        Algorithm::RoundRobin.matches_form_round_robin(remaining_matches)
      end

      pairings = rounds.first

      if pairings.nil?
        # FIXME: Tournament must be able to continue after one lap of round robin
        raise 'No valid rounds found'
        # pairings = match_teams(driver, teams).first # Just take the first round as a fallback
      end

      driver.create_matches(pairings.map(&:to_a))
    end

    def minimum_rounds(_driver)
      1
    end

    # private

    def match_teams(driver, teams = driver.ranked_teams) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return [[]] if teams.empty?

      teams = teams.clone

      # Assuming `teams` is ranked in order of preferred matching
      team = teams.shift
      matches = driver.get_team_matches(team)
      played_teams = matches.map { |m| driver.get_match_teams(m) }.flatten
      remaining_opponents = teams - played_teams
      Enumerator.new do |enum|
        remaining_opponents.each do |opponent|
          match = Set[team, opponent]
          other_teams = teams - match.to_a
          match_teams(driver, other_teams).each do |other_matches|
            enum.yield [match] + other_matches
          end
        end
      end
    end

    def all_matches(driver)
      teams = Algorithm::Util.padd_teams_even(driver.seeded_teams)

      Enumerator.new do |enum|
        teams.each_with_index do |team, index|
          teams[(index + 1)..].each do |opponent|
            enum.yield Set[team, opponent]
          end
        end
      end
    end

    # Driver proxy disregarding matches played in previous laps of round robin
    class VoetlabDriverProxy < DriverProxy
      def get_team_matches(team) # rubocop:disable Metrics/AbcSize
        matches = super
        return [] if (matches.count % (even_team_count - 1)).zero?

        match_sets = matches.group_by { |match| get_match_teams(match).to_set }

        current_round = match_sets.values.map(&:count).max # FIXME: Maybe use the `guess_round` function
        match_sets.values.map { |matches_in_set| matches_in_set[current_round - 1] }.compact
      end

      def even_team_count
        (seeded_teams.count.to_f / 2).ceil * 2
      end
    end

    private_constant :VoetlabDriverProxy
  end
end
