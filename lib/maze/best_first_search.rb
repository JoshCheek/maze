require 'maze/search_helpers'

class Maze
  class BestFirstSearch
    class PriorityQueue
      Node = Struct.new :object, :value

      attr_accessor :heuristic, :elements
      def initialize(&heuristic)
        self.heuristic = heuristic
        self.elements  = []
      end

      def <<(object)
        elements << Node.new(object, heuristic[object])
        bubble_up elements.length.pred
        self
      rescue
        require "pry"
        binding.pry
      ensure

        require "pry"
        binding.pry if elements.include? nil
      end

      def shift
        child = elements.min_by(&:value)
        return unless child
        index = elements.index child
        elements.delete_at index
        return child.object


        el0 = elements[0]
        to_return = el0.object
        min = elements.map(&:value).min

        require "pry"
        binding.pry if min < el0.value
        to_return
      # rescue
      #   require "pry"
      #   binding.pry
      # ensure
      #   require "pry"
      #   binding.pry if elements.include? nil
      #   elements[0] = elements.pop
      #   require "pry"
      #   binding.pry if elements.include? nil
      #   p elements
      #   bubble_down 0
      #   # require "pry"
      #   # binding.pry

      #   require "pry"
      #   binding.pry if elements.include? nil
      end

      def any?
        elements.any?
      end

      private

      def bubble_up(child_index)
        parent_index = parent_index_of(child_index)
        return if parent_index < 0
        parent        = elements[parent_index]
        child1        = elements[child_index]
        sibling_index = sibling_index_of child_index
        child2        = elements[sibling_index]
        child, child_index = if !child2 || child1.value < child2.value
                               [child1, child_index]
                             else
                               [child2, sibling_index]
                             end
        return if parent.value < child.value
        elements[parent_index] = child
        elements[child_index]  = parent
        bubble_up parent_index
      rescue

        require "pry"
        binding.pry
      end

      def bubble_down(parent_index)
        child_index1 = child_index_of(parent_index)
        child_index2 = 1 + child_index1
        return if elements.length <= child_index1
        parent = elements[parent_index]
        if elements.length <= child_index2
          child, child_index = elements[child_index1], child_index1
        else
          child1 = elements[child_index1]
          child2 = elements[child_index2]
          child, child_index = if child1.value < child2.value
                                 [child1, child_index1]
                               else
                                 [child2, child_index2]
                               end
        end
        return if parent.value <= child.value
        elements[parent_index] = child
        elements[child_index]  = parent
        bubble_down child_index
      end

      def parent_index_of(index)
        (index - 1) / 2
      end

      def child_index_of(index)
        (index + 1) * 2
      end

      def sibling_index_of(child_index)
        if child_index == child_index_of(parent_index_of(child_index))
          child_index + 1
        else
          child_index - 1
        end
      end
    end

    def self.call(attrs)
      new(attrs).call
    end

    NULL_CALLBACK = Proc.new { }

    attr_accessor :to_explore, :on_search, :came_from
    include SearchHelpers


    # would be nice to support "callback after you've explored all the nodes at this depth"
    # otherwise it seems to slow down based on how many heads there are
    def initialize(on_search:NULL_CALLBACK, **keyrest)
      super(**keyrest)
      self.on_search  = on_search
      self.came_from  = {start => nil}
      self.to_explore = PriorityQueue.new do |(x, y)|
        xdelta = finish[0] - x
        ydelta = finish[1] - y
        Math.sqrt xdelta**2 + ydelta**2
      end
      to_explore << start
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
      current = nil
      while to_explore.any?
        parent  = current
        current = to_explore.shift
        # require "pry"
        # binding.pry
        break if current == finish
        explored << current
        on_search.call current, self

        edges_for(current)
          .each { |edge| came_from[edge] = current }
          .each { |edge| to_explore << edge        }
      end

      if found?(finish)
        on_search.call finish, self
        true
      end
    end

    def build_success_path
      path_to(finish).reverse.each do |cell|
        success_path.unshift cell
      end
    end
  end
end
