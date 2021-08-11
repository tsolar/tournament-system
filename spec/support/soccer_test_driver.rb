require 'ostruct'

require 'tournament_system'

class SoccerTestDriver < TestDriver
  def initialize(options = {})
    super(options)
    @scores = options[:scores] || scores_from_winners(@teams, @winners)
    @matches = options[:matches] || @winners.keys.to_a
    @ranked_teams = options[:ranked_teams] || @teams.sort_by { |t| @scores[t] }.reverse # Highest score on top
    @team_matches = options[:team_matches] || build_team_matches_from_matches
  end

  private

  def scores_from_winners(_teams, winners)
    scores = Hash.new(0)
    winners.each do |match, winner|
      if winner.nil?
        scores[match[0]] += 1
        scores[match[1]] += 1
      else
        # FIXME: Should implement ranking based on goals scored
        scores[winner] += (match_bye?(match) ? 2.99 : 3.00)
      end
    end
    scores
  end
end
