require 'maze'

class Maze
  class DepthFirstSearch
    def self.call(attrs, &block)
      new(attrs, &block).call
    end

    attr_accessor :maze, :start, :finish, :callback, :explored
    attr_accessor :success_path, :failed_paths, :all_paths

    def initialize(maze:, start:, finish:, &callback)
      self.maze         = maze
      self.start        = start
      self.finish       = finish
      self.callback     = callback || Proc.new { }
      self.explored     = []
      self.failed_paths = []
      self.all_paths    = []
    end

    # Prob break this out into another class (ie RecursiveDepthFirstSearch), if I want to keep it
    # def recursive(current, visited=[])
    #   return [current] if current == finish
    #   visited << current
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
      explored << start
      callback.call start, self
      stack = [[start, edges_for(start, nil)]]

      loop do
        parent, children = stack.last

        if children.empty?
          stack.pop
          next
        end

        current = children.shift
        explored << current
        callback.call current, self

        if current == finish
          stack.push [current, []]
          break
        end

        edges = edges_for current, parent

        add_path :failed, (stack.map(&:first) << current) if edges.empty?

        edges.reject! { |edge| explored.include? edge }
        stack.push [current, edges]
      end
      add_path :success, stack.map(&:first)
      self
    end

    private

    def add_path(type, path)
      all_paths << path
      if type == :success
        self.success_path = path
      else
        self.failed_paths << path
      end
    end

    def edges_for(cell, parent)
      maze.edges_of(cell).select do |edge|
        maze.is?(edge, traversable: true) && edge != parent
      end
    end
  end
end
