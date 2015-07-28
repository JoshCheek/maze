require 'maze'

class Maze
  class DepthFirstSearch
    def self.call(attrs, &block)
      new(attrs, &block).call
    end

    attr_accessor :maze, :start, :finish, :on_search, :on_build_path
    attr_accessor :callback

    def initialize(maze:, start:, finish:, &callback)
      self.maze          = maze
      self.start         = start
      self.finish        = finish
      self.on_search     = on_search
      self.callback      = callback
    end

    # Prob break this out into another class (ie RecursiveDepthFirstSearch), if I want to keep it

    # def call
    #   recursive start, []
    # end

    # def recursive(current, visited=[])
    #   return [current] if current == finish

    #   visited << current
    #   display maze, heading: {text: 'Searching', colour: :blue},
    #                 green:   current,
    #                 blue:    visited,
    #                 red:     finish

    #   edges_of(maze, current)
    #     .select { |edge| path? maze, edge }
    #     .reject { |edge| visited.include? edge }
    #     .each   { |edge|
    #       path = recursive maze, edge, finish, visited
    #       return path.insert(0, current) if path
    #     }

    #   nil
    # end

    def call
      visited     = []
      paths_taken = []
      stack       = [
        [start, [start]]
      ]

      loop do
        parent, children = stack.last

        if children.empty?
          stack.pop
          next
        end

        current = children.shift
        visited << current
        break if current == finish

        callback.call current, visited, finish

        edges = maze.edges_of(current).select do |edge|
          maze.is?(edge, traversable: true) && edge != parent
        end

        paths_taken << (stack.map(&:first) << current) if edges.empty?

        edges.reject! { |edge| visited.include? edge }
        stack.push [current, edges]
      end

      paths_taken << stack.map(&:first)
      paths_taken
    end
  end
end
