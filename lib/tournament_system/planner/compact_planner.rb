module Planner
  # Implements a round planner that creates the most compact possible
  # arrangement of matches.
  module CompactPlanner
    extend Planner::EvenDistributionPlanner
    extend self
  end
end
