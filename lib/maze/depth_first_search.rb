require 'maze/search_helpers'

class Maze
  class DepthFirstSearch
    include SearchHelpers

    def self.call(attrs, &block)
      new(attrs, &block).call
    end

    attr_accessor :callback, :stack

    def initialize(**keyrest, &callback)
      super(**keyrest)
      self.callback = callback || Proc.new { }
      self.stack    = []
    end

    def call
      explored << start
      callback.call start, self
      stack.push [start, edges_for(start)]

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

        edges = edges_for current
        add_path :failed, (stack.map(&:first) << current) if edges.empty?
        stack.push [current, edges]
      end
      self
    end
  end
end
