describe Planner::CompactPlanner do
  describe '#plan_rounds' do
    it 'finds the most compact distribution of matches for 6 teams' do
      driver = TestDriver.new(
        teams: [1, 2, 3, 4, 5, 6],
        matches: [
          Match[1, 2], Match[3, 4], Match[5, 6],
          Match[1, 3], Match[5, 2], Match[6, 4],
          Match[1, 5], Match[6, 3], Match[4, 2],
          Match[1, 6], Match[4, 5], Match[2, 3],
          Match[1, 4], Match[2, 6], Match[3, 5],
        ]
      )
      field_count = 2
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds.size).to eq 8
    end

    it 'finds the most compact distribution of matches for 11 teams' do
      driver = TestDriver.new(teams: (1..11).to_a)
      TournamentSystem::RoundRobin.total_rounds(driver).times do
        TournamentSystem::RoundRobin.generate driver
        driver.matches = driver.created_matches
      end
      expect(driver.matches.size).to eq 66

      field_count = 4
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds.size).to eq 14
    end
  end
end
