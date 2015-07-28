require 'maze'

class Maze
  class BreadthFirstSearch
    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :maze, :start, :finish, :on_search, :on_build_path
    attr_accessor :came_from, :to_explore, :path

    def initialize(maze:, start:, finish:, on_search:NULL_CALLBACK, on_build_path:NULL_CALLBACK)
      self.maze          = maze
      self.start         = start
      self.finish        = finish
      self.on_search     = on_search
      self.on_build_path = on_build_path
      self.came_from     = {start => start}  # record the how we got to each cell so we can reconstruct the path
      self.to_explore    = [start]           # a queue of where to search next
    end

    def explored
      came_from.keys
    end

    def call
      # search until we run out of places to look, or find the target
      while finish != (current = to_explore.shift)
        on_search.call current, self
        maze.edges_of(current).each do |edge|
          next unless maze.is? edge, traversable: true
          next if     came_from.key? edge
          came_from[edge] = current
          to_explore << edge
        end
      end

      self.path = []
      while current != came_from[current]
        path << current
        current = came_from[current]
        on_build_path.call current, self
      end
      path
    end
  end
end
