require 'spec_helper'

RSpec.describe Maze::Generate do
  it 'generates a maze with the given width, height' do
    maze = Maze::Generate.call(width: 3, height: 5)
    expect(maze.width).to eq 3
    expect(maze.height).to eq 5
  end

  it 'randomly chooses a start and finish spot' do
    starts_and_finishes = 100.times.map do
      maze = Maze::Generate.call(width: 10, height: 10)
      [maze.start, maze.finish]
    end

    starts, finishes = starts_and_finishes.transpose
    expect(starts.uniq.length).to be > 1
    expect(finishes.uniq.length).to be > 1
  end

  it 'invokes a callback for each cell it paves' do
    seen_paved = []

    maze = Maze::Generate.call(width: 10, height: 10) do |paved, generate|
      seen_paved << paved
    end

    expect(seen_paved).to_not be_empty

    all_cells = 10.times.flat_map { |y| 10.times.map { |x| [x, y] } }

    all_cells.each do |cell|
      if seen_paved.include? cell
        expect(maze.is? cell, traversable: true).to be
      else
        expect(maze.is? cell, traversable: true).not_to be
      end
    end
  end

  describe 'paving' do
    it 'does not pave the edges of the maze' do
      maze = Maze::Generate.call(width: 10, height: 10)
      0.upto 9 do |i|
        expect(maze.type [i, 0]).to eq :wall
        expect(maze.type [0, i]).to eq :wall
        expect(maze.type [i, 9]).to eq :wall
        expect(maze.type [9, i]).to eq :wall
      end
    end

    it 'does not wind up with unjoined diagonals, or blocks of whitespace' do
      paved = []
      maze  = Maze::Generate.call(width: 10, height: 10) { |cell| paved << cell }

      paved.each do |cell|
        paved_corners = maze.corners_of(cell).select { |corner| paved.include? corner }
        paved_corners.each do |paved_corner|
          shared_edges = maze.shared_edges(cell, paved_corner)
          paved_and_shared = shared_edges.select { |edge| paved.include? edge }

          # shitty diagonals
          expect(paved_and_shared.length).to_not eq 0

          # blocks of whitespace
          expect(paved_and_shared.length).to_not eq 2

          # sanity
          expect(paved_and_shared.length).to eq 1
        end
      end
    end

  end
end
