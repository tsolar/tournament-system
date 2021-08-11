require 'tournament_system/algorithm/util'
require 'tournament_system/algorithm/group_pairing'
require 'graph_matching'
require 'graph_matching/integer_vertexes'

module TournamentSystem
  module Algorithm
    # This module provides algorithms for dealing with round robin tournament
    # systems.
    module RoundRobin
      extend self

      # Calculates the total number of rounds needed for round robin with a
      # certain amount of teams.
      #
      # @param teams_count [Integer] the number of teams
      # @return [Integer] number of rounds needed for round robin
      def total_rounds(teams_count)
        Util.padded_teams_even_count(teams_count) - 1
      end

      # Guess the next round (starting at 0) for round robin.
      #
      # @param teams_count [Integer] the number of teams
      # @param matches_count [Integer] the number of existing matches
      # @return [Integer] next round number
      def guess_round(teams_count, matches_count)
        matches_count / (Util.padded_teams_even_count(teams_count) / 2)
      end

      # Rotate array using round robin.
      #
      # @param array [Array<>] array to rotate
      # @param round [Integer] the round number, ie. amount to rotate by
      def round_robin(array, round)
        rotateable = array[1..]

        [array[0]] + rotateable.rotate(-round)
      end

      # Enumerate all round robin rotations.
      def round_robin_enum(array)
        Array.new(total_rounds(array.length)) do |index|
          round_robin(array, index)
        end
      end

      # Rotates teams and pairs them for a round of round robin.
      #
      # Uses {GroupPairing#fold} for pairing after rotating.
      #
      # @param teams [Array<team>] teams playing
      # @param round [Integer] the round number
      # @return [Array<Array(team, team)>] the paired teams
      def round_robin_pairing(teams, round)
        rotated = round_robin(teams, round)

        GroupPairing.fold(rotated)
      end

      # Determines whether a set of matches can be played in round
      # robin fashion, i.e. with every team playing every round
      #
      # FIXME: Maybe this is always true as long as there are no subgraphs with an
      # uneven number of vertices
      def matches_form_round_robin(matches) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        teams = Set.new
        graph = GraphMatching::Graph::Graph.new
        matches.each do |match|
          teams.merge(match)
          graph.add_edge(*match)
        end

        if !graph.connected?
          graph.each_connected_component do |subgraph|
            edges = graph.edges.select do |match|
              # Will always also include match[1] because the subgraph contains all connected vertices
              subgraph.include?(match[0])
            end
            valid_rr = matches_form_round_robin(edges.map(&:to_a))
            return false unless valid_rr
          end
          true
        else
          integer_graph, _legend = GraphMatching::IntegerVertexes.to_integers(graph)
          matching = integer_graph.maximum_cardinality_matching
          matching.edges.size == (teams.size.to_f / 2).ceil
        end
      end
    end
  end
end
