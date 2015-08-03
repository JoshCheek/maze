require 'maze'

class Maze
  class RecursiveDepthFirstSearch
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
      self.success_path = []
    end

    def call
      recursive start, []
      self
    end

    def recursive(current, path)
      path = [*path, current]
      explored << current
      callback.call current, self

      if current == finish
        add_path :success, path
        true
      else
        edges = edges_for current
        add_path :failed, path if edges.empty?
        edges.find { |edge| recursive edge, path unless explored.include? edge }
      end
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
        failed_paths << path
      end
    end
  end
end
