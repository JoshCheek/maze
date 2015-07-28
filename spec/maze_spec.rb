require 'maze'

RSpec.describe Maze do
  it 'has the given width/height'

  describe '#random_cell' do
    it 'chooses a cell within the x_min and x_max (including them)'
    it 'chooses a cell within the y_min and y_max (including them)'
    it 'chooses a cell of the given type'
  end

  describe '#type' do
    it 'returns the type of the cell, :wall, :path, :start, or :finish'
  end

  describe '#set' do
    it 'sets the type of the cell'
    it 'records the location, if it\'s a start or finish cell'
  end

  describe '#edges_of' do
    it 'returns the square to the left / right / top / bottom of the cell'
    it 'omits any of these that are off the board'
  end

  describe '#corners_of' do
    it 'returns the square to the upper-left / upper-right / lower-left / lower-right of the cell'
    it 'omits any of these that are off the board'
  end

  describe '#on_board?' do
    it 'returns true if the cell is within the bounds of the maze'
  end

  describe '#is?' do
    it 'returns true if the cell has the given type, x_min, x_max, y_min, y_max, traversability'
    it 'ignores any of these which are not present'
  end

  describe '#shared_edges' do
    it 'returns the set of edges that the cells have in common'
  end

  describe '#cell_line' do
    it 'projects the line to the given cell that much further out'
  end
end
