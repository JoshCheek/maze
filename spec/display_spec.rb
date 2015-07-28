require 'maze'

RSpec.describe Maze::Display do
  specify '.null returns an unenabled display'
  specify '#clear prints the clear escape sequence'
  it 'does not print when it is disabled'

  describe '#without_cursor' do
    it 'hides the cursor for the duration of the block'
    it 'ensures the cursor gets turned back on'
  end

  describe '#call' do
    it 'prints the header, and maze'
    it 'doesn\'t blow up when given the various colours (going to not bother testing their escape sequences)'
    it 'respects the provided duration'
    it 'defaults the duration to 0'
    context 'when printing the maze' do
      it 'prints "##" for a wall'
      it 'prints "  " for a path'
      it 'prints " S" for the start'
      it 'prints " F" for the finish'
    end
  end
end
