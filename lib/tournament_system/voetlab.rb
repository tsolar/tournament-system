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
      end

      driver.create_matches(pairings.map(&:to_a))
    end

    def minimum_rounds(_driver)
      1
    end

    # private

    def build_state(driver, options = {}) # rubocop:disable Metrics/AbcSize
      pairer = pairer_from_options(options)
      pairer_options = options[:pair_options] || {}

      state = pairer.build_state(driver, pairer_options)

      teams = state.teams

      state.matches = state.driver.matches_hash

      state.score_range = state.scores.values.max - state.scores.values.min
      state.average_score_difference = state.score_range / teams.length.to_f

      state.team_index_map = teams.map.with_index.to_h

      state
    end

    def rate_round(pairings, state, options = {})
      pairer = pairer_from_options(options)
      costs = pairings.map do |pair|
        home, away = pair.to_a
        pairer.cost_function(state, home, away)
      end
      costs.sum
    end

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

    def collect_past_pairings(driver)
      matches = driver.matches.map { |m| driver.get_match_teams(m) }.map(&:to_set)
      match_counts = matches.tally
      full_rr_count = matches.count / matches_per_round_robin(driver)
      match_counts.select { |_match, count| count == full_rr_count + 1 }.keys.to_set
    end

    def pairer_from_options(options)
      options[:pairer] || TournamentSystem::Swiss::Voetlab
    end

    def matches_per_round_robin(driver)
      team_count = driver.seeded_teams.count
      total_rounds = Algorithm::RoundRobin.total_rounds(team_count)
      matches_per_round = (team_count.to_f / 2).ceil
      total_rounds * matches_per_round
    end

    def flatten_set(sets)
      new_set = Set.new
      sets.each do |s|
        s.each do |e|
          new_set.add(e)
        end
      end
      new_set
    end

    # Driver proxy disregarding matches played in previous laps of round robin
    class VoetlabDriverProxy < DriverProxy
      def get_team_matches(team)
        matches = super
        return [] if matches.count == even_team_count - 1

        tally = matches.tally
        tally.select { |_m, c| c == tally.values.max }.keys
      end

      def even_team_count
        (seeded_teams.count.to_f / 2).ceil * 2
      end
    end

    private_constant :VoetlabDriverProxy
  end
end
