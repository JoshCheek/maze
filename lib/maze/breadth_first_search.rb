require 'maze/search_helpers'

class Maze
  class BreadthFirstSearch
    include SearchHelpers

    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :came_from, :to_explore, :on_search, :on_build_path

    # would be nice to support "callback after you've explored all the nodes at this depth"
    # otherwise it seems to slow down based on how many heads there are
    def initialize(on_search:NULL_CALLBACK, on_build_path:NULL_CALLBACK, **keyrest)
      super(**keyrest)
      self.on_search     = on_search
      self.on_build_path = on_build_path
      self.came_from     = {start => start}  # record the how we got to each cell so we can reconstruct the path
      self.to_explore    = [start]
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
        edges_for(current)
          .tap  { |edges| add_path :fail, build_path(current) if edges.empty? }
          .each { |edge| came_from[edge] = current }
          .each { |edge| to_explore << edge        }
      end
      current == finish
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
      path.unshift(cell = came_from[cell]) while cell != start
      path
    end
  end
end
