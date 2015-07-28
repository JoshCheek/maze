require 'spec_helper'

RSpec.describe Maze::Generate do
  it 'generates a maze with the given width, height'
  it 'randomly chooses a start and end spot'
  it 'invokes a callback for each cell it paves'

  describe 'paving' do
    it 'does not pave the edges of the maze'
    it 'does not wind up with diagonally located paths'
  end
end
