require 'maze/search_helpers'

class Maze
  class BreadthFirstSearch
    include SearchHelpers

    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :came_from, :to_explore, :on_search, :on_build_path, :chunked_search

    # would be nice to support "callback after you've explored all the nodes at this depth"
    # otherwise it seems to slow down based on how many heads there are
    def initialize(chunked_search:false, on_search:NULL_CALLBACK, on_build_path:NULL_CALLBACK, **keyrest)
      super(**keyrest)
      self.chunked_search = chunked_search
      self.on_search      = on_search
      self.on_build_path  = on_build_path
      self.came_from      = {start => start}  # record the how we got to each cell so we can reconstruct the path
      self.to_explore     = [start]
    end

    def explored
      came_from.keys
    end

    def call
      found = search
      build_success_path if found
      self
    end

    def found?(cell)
      came_from.key? cell
    end

    def path_to(cell)
      return [] unless cell
      path = [cell]
      path.unshift(cell = came_from[cell]) while cell != start
      path
    end

    private

    def search
      while to_explore.any? && to_explore.any? && !found?(finish)
        if chunked_search
          explore_now = to_explore.dup
          to_explore.clear
        else
          explore_now = [to_explore.shift]
        end

        on_search.call explore_now, self

        explore_now.each do |cell|
          current = cell
          edges_for(current)
            .tap  { |edges| add_path :fail, path_to(current) if edges.empty? }
            .each { |edge| came_from[edge] = current }
            .each { |edge| to_explore << edge        }
        end
      end

      if found?(finish)
        on_search.call [finish], self
        true
      end
    end

    def build_success_path
      path_to(finish).reverse.each do |cell|
        success_path.unshift cell
        on_build_path.call cell, self
      end
    end
  end
end
