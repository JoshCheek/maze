require 'maze/search_helpers'

class Maze
  class RecursiveDepthFirstSearch
    include SearchHelpers

    def self.call(attrs, &block)
      new(attrs, &block).call
    end

    attr_accessor :callback

    def initialize(attrs, &callback)
      super(attrs)
      self.callback = callback || Proc.new { }
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
  end
end
