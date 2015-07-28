require 'spec_helper'
require 'maze'

RSpec.describe Maze do
  let(:m1010) { Maze.new width: 10, height: 10 }
  let(:m12)   { Maze.new width: 1,  height: 2  }
  let(:m21)   { Maze.new width: 2,  height: 1  }

  it 'has the given width/height' do
    maze = Maze.new(width: 10, height: 10)
    expect(maze.width).to eq 10
    expect(maze.height).to eq 10
    expect(maze.to_raw_arrays.length).to eq 10
    maze.to_raw_arrays.each do |row|
      expect(row.length).to eq 10
    end
  end

  describe '#random_cell' do
    it 'chooses a cell within the x_min, x_max, y_min, and y_max (including them)' do
      cells = 5000.times.map do
        m1010.random_cell x_min: 2, x_max: 4, y_min: 3, y_max: 7
      end
      expect(cells.uniq.length).to_not eq 1
      xs, ys = cells.transpose.map(&:uniq)
      expect(xs.sort).to eq [*2..4]
      expect(ys.sort).to eq [*3..7]
    end

    it 'chooses a cell of the given type' do
      # finds both
      walls = 100.times.map { m12.random_cell type: :wall }.uniq.sort_by(&:last)
      expect(walls).to eq [[0, 0], [0, 1]]

      # now there is only one path and one wall
      m12.set :path, [0, 0]

      # finds the only wall
      walls = 100.times.map { m12.random_cell type: :wall }.uniq.sort_by(&:last)
      expect(walls).to eq [[0, 1]]

      # finds the only path
      paths = 100.times.map { m12.random_cell type: :path }.uniq.sort_by(&:last)
      expect(paths).to eq [[0, 0]]
    end
  end

  describe '#type' do
    it 'returns the type of the cell, :wall, :path, :start, or :finish' do
      m1010.set :wall   ,  [0, 0]
      m1010.set :path   ,  [1, 0]
      m1010.set :start  ,  [0, 1]
      m1010.set :finish ,  [1, 1]
      expect(m1010.type [0, 0]).to eq :wall
      expect(m1010.type [1, 0]).to eq :path
      expect(m1010.type [0, 1]).to eq :start
      expect(m1010.type [1, 1]).to eq :finish
    end
  end

  describe '#set' do
    it 'sets the type of the cell' do
      expect(m1010.type [0, 0]).to eq :wall
      m1010.set :start, [0, 0]
      expect(m1010.type [0, 0]).to eq :start
    end

    it 'records the location, if it\'s a start or finish cell' do
      expect(m1010.start).to eq nil
      expect(m1010.finish).to eq nil

      m1010.set :path, [0, 0]
      m1010.set :path, [1, 1]

      expect(m1010.start).to eq nil
      expect(m1010.finish).to eq nil

      m1010.set :start,  [0, 0]
      m1010.set :finish, [1, 1]

      expect(m1010.start).to eq [0, 0]
      expect(m1010.finish).to eq [1, 1]
    end

    it 'blows up if given an unknown type' do
      expect { m1010.set :wat, [1, 1] }.to raise_error ArgumentError, /wat/
    end
  end

  describe '#edges_of' do
    it 'returns the square to the left / right / top / bottom of the cell' do
      expect(m1010.edges_of([1, 1]).sort).to eq [
        [0, 1], # left
        [1, 0], # above
        [1, 2], # below
        [2, 1], # right
      ]
    end

    it 'omits any of these that are off the board' do
      expect(m12.edges_of([0, 0])).to eq [[0, 1]]
      expect(m12.edges_of([0, 1])).to eq [[0, 0]]
      expect(m21.edges_of([0, 0])).to eq [[1, 0]]
      expect(m21.edges_of([1, 0])).to eq [[0, 0]]
    end
  end

  describe '#corners_of' do
    it 'returns the square to the upper-left / upper-right / lower-left / lower-right of the cell' do
      expect(m1010.corners_of([1, 1]).sort).to eq [
        [0, 0], # upper-left
        [0, 2], # lower-left
        [2, 0], # upper-right
        [2, 2], # lower-right
      ]
    end

    it 'omits any of these that are off the board' do
      expect(m1010.corners_of([0, 0])).to eq [[1, 1]]
      expect(m1010.corners_of([9, 0])).to eq [[8, 1]]
      expect(m1010.corners_of([0, 9])).to eq [[1, 8]]
      expect(m1010.corners_of([9, 9])).to eq [[8, 8]]
    end
  end

  describe '#on_board?' do
    it 'returns true if the cell is within the bounds of the maze' do
      expect(m1010.on_board? [ 0,  0]).to     be # top and left
      expect(m1010.on_board? [ 9,  9]).to     be # bottom and right

      expect(m1010.on_board? [-1,  0]).to_not be
      expect(m1010.on_board? [ 0, -1]).to_not be
      expect(m1010.on_board? [10,  0]).to_not be
      expect(m1010.on_board? [ 0, 10]).to_not be
    end
  end

  describe '#is?' do
    it 'returns whether the cell has the given type' do
      m1010.set :path, [1, 1]

      expect(m1010.is? [0, 0], type: :wall).to     be
      expect(m1010.is? [1, 1], type: :wall).to_not be

      expect(m1010.is? [0, 0], type: :path).to_not be
      expect(m1010.is? [1, 1], type: :path).to     be
    end

    it 'returns whether the cell has the given x_min' do
      expect(m1010.is? [0, 0], x_min: 1).to_not be
      expect(m1010.is? [1, 0], x_min: 1).to     be
      expect(m1010.is? [2, 0], x_min: 1).to     be
    end

    it 'returns whether the cell has the given x_max' do
      expect(m1010.is? [0, 0], x_max: 1).to     be
      expect(m1010.is? [1, 0], x_max: 1).to     be
      expect(m1010.is? [2, 0], x_max: 1).to_not be
    end

    it 'returns whether the cell has the given y_min' do
      expect(m1010.is? [0, 0], y_min: 1).to_not be
      expect(m1010.is? [0, 1], y_min: 1).to     be
      expect(m1010.is? [0, 2], y_min: 1).to     be
    end

    it 'returns whether the cell has the given y_max' do
      expect(m1010.is? [0, 0], y_max: 1).to     be
      expect(m1010.is? [0, 1], y_max: 1).to     be
      expect(m1010.is? [0, 2], y_max: 1).to_not be
    end

    it 'returns whether the cell has the given traversability' do
      expect(m1010.is? [0, 0], traversable:  true).to_not be
      expect(m1010.is? [0, 0], traversable: false).to     be
    end

    it 'considers paths, start, and finish to be traversable' do
      m1010.set :wall,   [0, 0]
      m1010.set :path,   [1, 1]
      m1010.set :start,  [2, 2]
      m1010.set :finish, [3, 3]
      expect(m1010.is? [0, 0], traversable:  true).to_not be
      expect(m1010.is? [0, 0], traversable: false).to     be

      expect(m1010.is? [1, 1], traversable:  true).to     be
      expect(m1010.is? [1, 1], traversable: false).to_not be

      expect(m1010.is? [2, 2], traversable:  true).to     be
      expect(m1010.is? [2, 2], traversable: false).to_not be

      expect(m1010.is? [2, 2], traversable:  true).to     be
      expect(m1010.is? [2, 2], traversable: false).to_not be
    end

    it 'raises an error if the cell is not on the board' do
      expect { m1010.is? [-1,  0], x_max: 5 }.to raise_error IndexError
      expect { m1010.is? [10,  0], x_min: 5 }.to raise_error IndexError
      expect { m1010.is? [ 0, -1], y_max: 5 }.to raise_error IndexError
      expect { m1010.is? [ 0, 10], y_min: 5 }.to raise_error IndexError
    end

    it 'ignores the type, when set to :any' do
      m1010.set :wall,   [0, 0]
      m1010.set :path,   [1, 1]
      m1010.set :start,  [2, 2]
      m1010.set :finish, [3, 3]
      expect(m1010.is? [0, 0], type: :any).to be
      expect(m1010.is? [1, 1], type: :any).to be
      expect(m1010.is? [2, 2], type: :any).to be
      expect(m1010.is? [3, 3], type: :any).to be
    end

    it 'blows up if given an unknown criteria' do
      expect { m1010.is? [0, 0], wat: true }.to raise_error ArgumentError, /wat/
    end
  end

  describe '#shared_edges' do
    it 'returns the set of edges that the cells have in common' do
      expect(m1010.shared_edges [1, 1], [1, 1]).to eq m1010.edges_of([1, 1])
      expect(m1010.shared_edges([0, 0], [1, 1]).sort).to eq [[0, 1], [1, 0]]
      expect(m1010.shared_edges([1, 1], [0, 0]).sort).to eq [[0, 1], [1, 0]]
    end
  end

  describe '#cell_line' do
    it 'projects the line to the given cell that much further out' do
      expect(m1010.cell_line [5, 5], [4, 4]).to eq [3, 3] # upper left
      expect(m1010.cell_line [5, 5], [5, 4]).to eq [5, 3] # above
      expect(m1010.cell_line [5, 5], [6, 4]).to eq [7, 3] # upper right
      expect(m1010.cell_line [5, 5], [4, 5]).to eq [3, 5] # left
      expect(m1010.cell_line [5, 5], [6, 5]).to eq [7, 5] # right
      expect(m1010.cell_line [5, 5], [4, 6]).to eq [3, 7] # lower left
      expect(m1010.cell_line [5, 5], [5, 6]).to eq [5, 7] # below
      expect(m1010.cell_line [5, 5], [6, 6]).to eq [7, 7] # lower right

      expect(m1010.cell_line [5, 5], [3, 3]).to eq [1, 1] # two out
    end
  end
end
