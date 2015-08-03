require 'maze'

class Maze
  class BreadthFirstSearch
    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :maze, :start, :finish, :on_search, :on_build_path
    attr_accessor :came_from, :to_explore, :success_path, :failed_paths

    def initialize(maze:, start:, finish:, on_search:NULL_CALLBACK, on_build_path:NULL_CALLBACK)
      self.maze          = maze
      self.start         = start
      self.finish        = finish
      self.on_search     = on_search
      self.on_build_path = on_build_path
      self.came_from     = {start => start}  # record the how we got to each cell so we can reconstruct the path
      self.to_explore    = [start]           # a queue of where to search next
      self.failed_paths  = []
      self.success_path  = []
    end

    def explored
      came_from.keys
    end

    def call
      # search until we run out of places to look, or find the target
      while finish != (current = to_explore.shift)
        on_search.call current, self

        edges = maze.edges_of(current)
                    .select { |edge| maze.is? edge, traversable: true }
                    .reject { |edge| came_from.key? edge              }

        failed_paths << build_path(current) if edges.empty?

        edges.each { |edge| came_from[edge] = current }
             .each { |edge| to_explore << edge        }
      end

      path = build_path current
      while path.any?
        success_path.unshift path.pop
        on_build_path.call success_path.first, self
      end

      self
    end

    private

    def build_path(cell)
      path = [cell]
      while cell != start
        cell = came_from[cell]
        path.unshift cell
      end
      path
    end
  end
end
