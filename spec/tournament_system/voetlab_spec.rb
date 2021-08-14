describe TournamentSystem::Voetlab do
  describe '#minimum_rounds' do
    it 'calls Algorithm::Swiss#minimum_rounds' do
      driver = instance_double('Driver')
      expect(described_class.minimum_rounds(driver)).to eq(1)
    end
  end

  describe '#generate' do
    it 'completes the round robin' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        matches: [[1, 2], [3, 4], [5, nil], [1, 3], [5, 2], [4, nil], [1, 5], [3, nil], [4, 2], [1, nil], [4, 5],
                  [2, 3],]
      )

      matches = described_class.generate(driver)

      expect(matches).to eq [
        [5, 3], [4, 1], [2, nil],
      ]
    end

    it 'and generates matches' do
      driver = SoccerTestDriver.new(teams: [1, 2, 3, 4, 5], scores: { 1 => 5, 2 => 4, 3 => 3, 4 => 2, 5 => 1 })

      matches = described_class.generate(driver)

      # Should match strongest teams together
      expect(matches).to eq [
        [1, 2], [3, 4], [5, nil],
      ]
    end

    it 'generates matches round 2' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: { [1, 2] => 1, [3, 4] => 3, [5, nil] => 5 }
      )

      matches = described_class.generate(driver)

      # Should pit winners against winners and losers against losers
      # with a bye for the team with the lowest score
      expect(matches).to eq [
        [3, 1], [5, 4], [2, nil],
      ]
    end

    it 'generates matches round 3' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: { [1, 2] => 1, [3, 4] => 3, [5, nil] => 5, [1, 5] => 5, [4, 2] => 2, [3, nil] => 3 }
      )

      matches = described_class.generate(driver)

      expect(matches).to eq [
        [5, 3], [2, nil], [1, 4],
      ]
    end

    it 'generates matches round 4' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: { [1, 2] => 1, [3, 4] => 3, [5, nil] => 5, [1, 5] => 5, [4, 2] => 2, [3, nil] => 3, [1, 3] => 1,
                   [4, nil] => 4, [2, 5] => 5, }
      )

      matches = described_class.generate(driver)

      expect(matches).to eq [
        [5, 3], [1, 4], [2, nil],
      ]
    end

    it 'generates matches round 5' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: { [1, 2] => 1, [3, 4] => 3, [5, nil] => 5, [1, 5] => 5, [4, 2] => 2, [3, nil] => 3, [1, 3] => 1,
                   [4, nil] => 4, [2, 5] => 5, [1, 4] => 1, [3, 5] => 5, [2, nil] => 2, }
      )

      matches = described_class.generate(driver)

      expect(matches).to eq [
        [5, 4], [1, nil], [3, 2],
      ]
    end

    it 'calls generates matches round 6' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: {
          [1, 2] => 1, [3, 4] => 3, [5, nil] => 5,
          [1, 5] => 5, [4, 2] => 2, [3, nil] => 3,
          [1, 3] => 1, [4, nil] => 4, [2, 5] => 5,
          [1, 4] => 1, [3, 5] => 5, [2, nil] => 2,
          [1, nil] => 1, [2, 3] => 3, [4, 5] => 5,
        }
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).to eq [
        [5, 1], [3, 2], [4, nil],
      ]
    end

    it 'gives expected results in scenario 1' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5],
        winners: {
          [2, 5] => 5, [3, 4] => 4, [1, nil] => 1,
          [1, 5] => nil, [2, 3] => 3, [4, nil] => 4,
          [1, 3] => nil, [4, 2] => nil, [5, nil] => 5,
          [1, 2] => nil, [4, 5] => 4, [3, nil] => 3,
          [1, 4] => 1, [3, 5] => nil, [2, nil] => 2,
        }
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).to eq [
        [4, 1], [5, 3], [2, nil],
      ]
    end

    it 'gives expected results in scenario 2' do
      driver = SoccerTestDriver.new(
        teams: [1, 2, 3, 4, 5, 6],
        winners: {
          [5, 4] => 4, [3, 2] => 3, [1, 6] => nil,
          [4, 3] => 3, [6, 5] => 6, [1, 2] => nil,
          # [3, 6] => nil, [4, 1] => nil, [2, 5] => 5,
        }
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).not_to eq [
        [3, 6], [4, 1], [2, 5],
      ]
    end

    it 'works with many teams' do
      driver = TestDriver.new(
        teams: (1..32).to_a,
        ranked_teams: (1..32).to_a
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).to eq [
        [1, 2], [3, 4], [5, 6],
        [7, 8], [9, 10], [11, 12],
        [13, 14], [15, 16], [17, 18],
        [19, 20], [21, 22], [23, 24],
        [25, 26], [27, 28], [29, 30],
        [31, 32],
      ]

      driver = TestDriver.new(
        teams: driver.teams, ranked_teams: driver.ranked_teams, matches: driver.matches + matches
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).to eq [
        [1, 3], [2, 4], [5, 7],
        [6, 8], [9, 11], [10, 12],
        [13, 15], [14, 16], [17, 19],
        [18, 20], [21, 23], [22, 24],
        [25, 27], [26, 28], [29, 31],
        [30, 32],
      ]

      driver = TestDriver.new(
        teams: driver.teams, ranked_teams: driver.ranked_teams, matches: driver.matches + matches
      )

      matches = described_class.generate(driver)

      # Since this is a new lap of round robin, teams should again be matched solely based on score
      expect(matches).to eq [
        [1, 4], [2, 3], [5, 8],
        [6, 7], [9, 12], [10, 11],
        [13, 16], [14, 15], [17, 20],
        [18, 19], [21, 24], [22, 23],
        [25, 28], [26, 27], [29, 32],
        [30, 31],
      ]
    end
  end

  describe '#match_teams' do
    it 'generates the correct matches' do
      driver = TestDriver.new(teams: [1, 2, 3, 4, 5, 6])

      enum = described_class.match_teams(driver)
      rounds = enum.to_a
      expect(rounds.count).to eq 5 * 3 * 1
      expect(rounds.shift).to eq [Set[1, 2], Set[3, 4], Set[5, 6]]
      expect(rounds.shift).to eq [Set[1, 2], Set[3, 5], Set[4, 6]]
      expect(rounds.shift).to eq [Set[1, 2], Set[3, 6], Set[4, 5]]
      expect(rounds.shift).to eq [Set[1, 3], Set[2, 4], Set[5, 6]]
      expect(rounds.shift).to eq [Set[1, 3], Set[2, 5], Set[4, 6]]
      expect(rounds.shift).to eq [Set[1, 3], Set[2, 6], Set[4, 5]]
      expect(rounds.shift).to eq [Set[1, 4], Set[2, 3], Set[5, 6]]
      expect(rounds.shift).to eq [Set[1, 4], Set[2, 5], Set[3, 6]]
      expect(rounds.shift).to eq [Set[1, 4], Set[2, 6], Set[3, 5]]
      expect(rounds.shift).to eq [Set[1, 5], Set[2, 3], Set[4, 6]]
      expect(rounds.shift).to eq [Set[1, 5], Set[2, 4], Set[3, 6]]
      expect(rounds.shift).to eq [Set[1, 5], Set[2, 6], Set[3, 4]]
      expect(rounds.shift).to eq [Set[1, 6], Set[2, 3], Set[4, 5]]
      expect(rounds.shift).to eq [Set[1, 6], Set[2, 4], Set[3, 5]]
      expect(rounds.shift).to eq [Set[1, 6], Set[2, 5], Set[3, 4]]
    end

    it 'generates the correct matches with some matches played' do
      driver = TestDriver.new(teams: [1, 2, 3, 4, 5, 6], matches: [[1, 4], [2, 3], [5, 6]])

      enum = described_class.match_teams(driver)
      rounds = enum.to_a
      expect(rounds.shift).to eq [Set[1, 2], Set[3, 5], Set[4, 6]]
      expect(rounds.shift).to eq [Set[1, 2], Set[3, 6], Set[4, 5]]
      expect(rounds.shift).to eq [Set[1, 3], Set[2, 5], Set[4, 6]]
      expect(rounds.shift).to eq [Set[1, 3], Set[2, 6], Set[4, 5]]
      expect(rounds.shift).to eq [Set[1, 5], Set[2, 4], Set[3, 6]]
      expect(rounds.shift).to eq [Set[1, 5], Set[2, 6], Set[3, 4]]
      expect(rounds.shift).to eq [Set[1, 6], Set[2, 4], Set[3, 5]]
      expect(rounds.shift).to eq [Set[1, 6], Set[2, 5], Set[3, 4]]
    end
  end

  describe '#all_matches' do
    it 'generated all matches' do
      driver = TestDriver.new(teams: [1, 2, 3, 4, 5, 6], matches: [[1, 4], [2, 3], [5, 6]])

      matches = described_class.all_matches(driver).to_a
      expect(matches.count).to eq 15

      expect(matches).to eq [
        Set[1, 2], Set[1, 3], Set[1, 4],
        Set[1, 5], Set[1, 6], Set[2, 3],
        Set[2, 4], Set[2, 5], Set[2, 6],
        Set[3, 4], Set[3, 5], Set[3, 6],
        Set[4, 5], Set[4, 6], Set[5, 6],
      ]
    end
  end
end
