describe Planner::SimplePlanner do
  describe '#plan_rounds' do
    it 'adds matches to available fields' do
      driver = TestDriver.new(
        teams: [1, 2, 3, 4, 5, 6],
        matches: [Match[1, 2], Match[3, 4], Match[5, 6]]
      )
      field_count = 3
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, 6]],
      ]
    end

    it 'does not require a field for a bye' do
      driver = TestDriver.new(
        teams: [1, 2, 3, 4, 5],
        matches: [Match[1, 2], Match[3, 4], Match[5, nil]]
      )
      field_count = 2
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, nil]],
      ]
    end

    it 'divides matches over multiple rounds if there are insufficient fields' do
      driver = TestDriver.new(
        teams: [1, 2, 3, 4, 5, 6],
        matches: [Match[1, 2], Match[3, 4], Match[5, 6], Match[1, 3], Match[5, 2], Match[6, 4]]
      )
      field_count = 3
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds).to eq [
        [[1, 2], [3, 4], [5, 6]],
        [[1, 3], [5, 2], [6, 4]],
      ]
    end

    it 'plans matches against the same team in different rounds' do
      driver = TestDriver.new(
        teams: [1, 2, 3],
        matches: [Match[1, 2], Match[1, 3]]
      )
      field_count = 2
      rounds = described_class.plan_rounds driver, driver.matches, field_count

      expect(rounds).to eq [
        [[1, 2]],
        [[1, 3]],
      ]
    end
  end
end
