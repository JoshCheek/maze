require 'maze'

class Maze
  class BreadthFirstSearch
    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :maze, :start, :finish, :on_search, :on_build_path
    attr_accessor :came_from, :to_explore, :success_path, :failed_paths, :all_paths

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
      self.all_paths     = []
    end

    def explored
      came_from.keys
    end

    def call
      found = search
      build_success_path if found
      self
    end

    private

    def search
      while to_explore.any? && finish != (current = to_explore.shift)
        on_search.call current, self
        viable_edges_of(current)
          .tap  { |edges| add_path :fail, build_path(current) if edges.empty? }
          .each { |edge| came_from[edge] = current }
          .each { |edge| to_explore << edge        }
      end
      current == finish
    end

    def viable_edges_of(cell)
      maze.edges_of(cell)
          .select { |edge| maze.is? edge, traversable: true }
          .reject { |edge| came_from.key? edge              }
    end

    def build_success_path
      build_path(finish).reverse.each do |cell|
        success_path.unshift cell
        on_build_path.call cell, self
      end
    end


    def build_path(cell)
      return [] unless cell
      path = [cell]
      while cell != start
        cell = came_from[cell]
        path.unshift cell
      end
      path
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
