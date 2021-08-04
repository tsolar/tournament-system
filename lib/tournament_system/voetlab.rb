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
    def generate(driver, options = {})
      available_rounds = available_round_robin_rounds(driver)

      state = build_state(driver, options)
      ordered_rounds = available_rounds.sort_by do |pairings|
        rate_round(pairings, state, options)
      end

      pairings = ordered_rounds.first.map(&:to_a)

      driver.create_matches(pairings)
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

    def available_round_robin_rounds(driver) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # By permuting teams, we get all possible round robin tournament configurations
      all_rr_tournaments = driver.seeded_teams.permutation.map { |teams| round_robin_tournament(driver, teams) }.to_set

      # Collect past matches that we do not want to repeat
      # Because there can be multiple full round robins, we only take the matches that have been repeated the most
      matches = driver.matches.map(&:to_set)
      match_counts = matches.tally
      full_rr_count = matches.count / matches_per_round_robin(driver)
      past_pairings = match_counts.select { |_match, count| count == full_rr_count + 1 }.keys.to_set

      # Filter out round robin tournaments that do not include all past rounds
      # Those tournaments will not be able to complete fully
      valid_rr_tournaments = all_rr_tournaments.select do |rounds|
        played_rounds = rounds.reject { |pairings| (pairings & past_pairings).empty? }
        # If past pairings are the only pairings, we know rounds are identical
        past_pairings == flatten_set(played_rounds)
      end

      # Collect all possibe rounds
      all_rounds = flatten_set(valid_rr_tournaments)

      # Combine the rounds of all valid round robin tournaments and filter out
      # rounds that have already been played
      all_rounds.select { |pairings| (pairings & past_pairings).empty? }
    end

    def round_robin_tournament(_driver, teams)
      total_rounds = Algorithm::RoundRobin.total_rounds(teams.count)
      all_rounds = (1..total_rounds).map do |round|
        Algorithm::RoundRobin.round_robin_pairing(Algorithm::Util.padd_teams_even(teams), round).map(&:to_set).to_set
      end

      all_rounds.to_set
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
  end
end
