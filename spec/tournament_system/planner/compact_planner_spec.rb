describe Planner::CompactPlanner do
  describe '#plan_rounds' do
    it 'adds matches to available fields' do
      matches = [Match[1, 2], Match[3, 4], Match[5, 6]]
      field_count = 3
      rounds = described_class.plan_rounds matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, 6]],
      ]
    end

    it 'does not require a field for a bye' do
      matches = [Match[1, 2], Match[3, 4], Match[5, nil]]
      field_count = 2
      rounds = described_class.plan_rounds matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, nil]],
      ]
    end

    it 'divides matches over multiple rounds if there are insufficient fields' do
      matches = [Match[1, 2], Match[3, 4], Match[5, 6], Match[1, 3], Match[5, 2], Match[6, 4]]
      field_count = 3
      rounds = described_class.plan_rounds matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, 6]],
        [[1, 3], [5, 2], [6, 4]],
      ]
    end

    it 'plans matches against the same team in different rounds' do
      matches = [Match[1, 2], Match[1, 3]]
      field_count = 2
      rounds = described_class.plan_rounds matches, field_count

      expect(rounds).to eq [
        [[1, 2]],
        [[1, 3]],
      ]
    end

    it 'distribute round evenly between rounds' do
      matches = [Match[1, 2], Match[3, 4], Match[5, 6], Match[7, 8], Match[9, 10], Match[11, 12]]
      field_count = 4
      rounds = described_class.plan_rounds matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, 6]],
        [[7, 8], [9, 10], [11, 12]],
      ]
    end

    it 'finds the most compact distribution of matches for 6 teams' do
      matches = [
        Match[1, 2], Match[3, 4], Match[5, 6],
        Match[1, 3], Match[5, 2], Match[6, 4],
        Match[1, 5], Match[6, 3], Match[4, 2],
        Match[1, 6], Match[4, 5], Match[2, 3],
        Match[1, 4], Match[2, 6], Match[3, 5],
      ]
      field_count = 2
      rounds = described_class.plan_rounds matches, field_count

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
      rounds = described_class.plan_rounds driver.matches, field_count

      expect(rounds.size).to eq 14
    end
  end
end
