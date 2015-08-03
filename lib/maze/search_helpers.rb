require 'set'
require 'maze'

class Maze
  module SearchHelpers
    attr_accessor :success_path, :failed_paths, :all_paths, :explored
    attr_accessor :maze, :start, :finish

    def initialize(maze:, start:, finish:)
      self.maze         = maze
      self.start        = start
      self.finish       = finish
      self.explored     = Set.new
      self.all_paths    = []
      self.failed_paths = []
      self.success_path = []
    end

    private

    def edges_for(cell)
      maze.edges_of(cell)
          .select { |edge| maze.is? edge, traversable: true }
          .reject { |edge| explored.include? edge }
    end

    def add_path(type, path)
      all_paths << path
      if type == :success
        self.success_path = path
      else
        self.failed_paths << path
      end
    end
  end
end
