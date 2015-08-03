require 'maze'

class Maze
  class DepthFirstSearch
    def self.call(attrs, &block)
      new(attrs, &block).call
    end

    attr_accessor :maze, :start, :finish, :callback, :explored, :stack
    attr_accessor :success_path, :failed_paths, :all_paths

    def initialize(maze:, start:, finish:, &callback)
      self.maze         = maze
      self.start        = start
      self.finish       = finish
      self.callback     = callback || Proc.new { }
      self.explored     = []
      self.failed_paths = []
      self.all_paths    = []
      self.success_path = []
      self.stack        = []
    end

    def call
      explored << start
      callback.call start, self
      stack.push [start, edges_for(start, nil)]

      while stack.any?
        parent, children = stack.last

        # we may have explored it while going down one of its sibling paths
        children.shift while children.first && explored.include?(children.first)
        next stack.pop if children.empty?

        current = children.shift
        explored << current
        callback.call current, self

        if current == finish
          add_path :success, (stack.map(&:first) << current)
          break
        end

        edges = edges_for current, parent
        edges.reject! { |edge| explored.include? edge }
        add_path :failed, (stack.map(&:first) << current) if edges.empty?
        stack.push [current, edges]
      end
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
