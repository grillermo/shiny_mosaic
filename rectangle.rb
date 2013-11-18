
class Rectangle
  attr_accessor :width, :height, :content, :corners, :grid, :parent_rectangle, :sub_rectangles, :size, :sizes
  @@sizes = ['small','vertical','large']

  def initialize(width: 1, height: 1, cell_width: 1, cell_height: 1, content: 0, size: @@sizes.sample)
    @sizes = @@sizes
    @size = size
    @width = width / cell_width
    @height = height / cell_height
    @content = content
    @corners = {:top => {:left => {:x=>0,:y=>0},:right => {:x=>0,:y=>0}},
                :bottom => {:left => {:x=>0,:y=>0},:right => {:x=>0,:y=>0}},
                }
    @sub_rectangles = []
    @parent_rectangle = nil
    if @width > 1 && @height > 1
      @grid = self.build_grid
    end
  end

  def empty
    @content == 0
  end

  def insertion_coordinates
    self.corners[:top][:left]
  end

  def has_parent?
    @parent_rectangle ? true : false
  end

  def build_grid
    grid = []
    (1..@height).each do |x|
      row = []
      (1..@width).each do |y|
        row.push Rectangle.new(content: @content)
      end
      grid.push row
    end
    grid
  end

  def enough_space_below(starting_row,right_y_corner,rectangle)
    # Test if below there is enough space to acomodate our rectangle

    available_height = 0

    # We need the limits with +1 because the coordinates are 0 based and the widths are not
    ending_row = starting_row + (rectangle.height - 1)
    left_y_corner = right_y_corner - (rectangle.width - 1)


    # We asume there is at least one row available because thats where we tested the width
    height_available = 1
    # If this is the unit we don't need to test any further
    if height_available == rectangle.height
      return {'x'=>starting_row,'y'=>right_y_corner}
    end

    clean_rows = 0
    x = 0
    y = 0
    for row in @grid do
      if x >= starting_row && x <= ending_row
        # we are on the rows that could have enough space
        y = 0
        for cell in row do
          # Flag to determine if this row has enough space
          row_clean = false
          if y >= left_y_corner && y <= right_y_corner
            # We are on the cell that could have enough space
            if cell.empty
              # so this row has as least one cell with content
              row_clean = true
            end
          end
          if row_clean
            clean_rows += 1
          end
          if clean_rows >= rectangle.height
              return true
          end
          y += 1
        end
      end
      x += 1
    end
    return false
  end


  def it_fits(rectangle)
    # Returns the coordinates of the top most left cell where this
    # rectangle fits in the grid or False

    # We will compare zero based coordinates with dimensions so we need to compensate
    # reducing by one
    width_to_fit = rectangle.width

    x = 0
    y = 0
    for row in @grid do
      y = 0
      # Each row reset the counter
      available_width = 0
      for cell in row do
        if !cell.empty
          # A single non empty cell resets our counter
          # Or if the row changes
          available_width = 0
        else
          available_width += 1
          if available_width >= width_to_fit
            # We found a row subset with enough width lets check below this subset
            if enough_space_below(x,y,rectangle)
              # Ok we have enough, lets move on
              return {:x => x,:y => y}
            end
          end
        end
        y += 1
      end
      x += 1
    end

    return false
  end

  def save_sub_rectangle(rectangle)
    rectangle.corners[:top][:left] = {:x => rectangle.corners[:top][:right][:x],
                                      :y => rectangle.corners[:top][:right][:y]-(rectangle.width-1)}

    rectangle.corners[:bottom][:left] = {:x => rectangle.corners[:top][:right][:x]+(rectangle.height-1),
                                         :y => rectangle.corners[:top][:left][:y]}

    rectangle.corners[:bottom][:right] =  {:x => rectangle.corners[:bottom][:left][:x],
                                           :y => rectangle.corners[:top][:right][:y] }
    rectangle.parent_rectangle = self
    @sub_rectangles.push rectangle
  end

  def insert_rectangle(rectangle)
    # Tries to insert a sub rectangle and updates its coordinates
    rectangle.corners[:top][:right] = self.it_fits(rectangle)

    if rectangle.corners[:top][:right]
      # If it fits, we can save it
      self.save_sub_rectangle rectangle
      # Actual insertion
      @grid[rectangle.corners[:top][:left][:x]..rectangle.corners[:bottom][:left][:x]].each_with_index do |row,x|
        row[rectangle.corners[:top][:left][:y]..rectangle.corners[:top][:right][:y]].each_with_index do |cell,y|
          cell.content = rectangle.content
        end
      end
      return rectangle
    else
      return false
    end
  end

  def find_sub_rectangle(rectangle)
  end

  def find_neighbour_with_coordinates(coordinates)
    @parent_rectangle.find_sub_rectangle_with_coordinates(coordinates)
  end

  def find_sub_rectangle_with_coordinates(coordinates)
    puts "finding #{coordinates}"
    @sub_rectangles.each do |rectangle|
      puts rectangle.corners
      if coordinates[:x] >= rectangle.corners[:top][:left][:x] && coordinates[:y] >= rectangle.corners[:top][:left][:y] &&
         coordinates[:x] <= rectangle.corners[:bottom][:right][:x] && coordinates[:y] <= rectangle.corners[:bottom][:right][:y]
        return rectangle
      end
    end
    return false
  end

  def remove_sub_rectangle(rectangle)
    if rectangle.parent_rectangle == self
      @sub_rectangles.delete(rectangle)
      # Clear the grid
      @grid[rectangle.corners[:top][:left][:x]..rectangle.corners[:bottom][:left][:x]].each_with_index do |row,x|
        row[rectangle.corners[:top][:left][:y]..rectangle.corners[:top][:right][:y]].each_with_index do |cell,y|
          cell.content = 0
        end
      end
    else
      raise 'Subrectangle not found in this rectangle'
    end
  end

  def render
    string = "\n"
    for row in @grid
      string += "\n"
      i = 0
      for cell in row
        i += 1
        string += "%s"%cell.content
      end
    end
    string += "\n"
    printf string
  end

  # Methods used to mutate the sub rectangle contents
  def grow?
    # 50 % chance of splitting
    [true,false].sample
  end

  def next_size
    if grow?
      case @size
        when 'small'
          return 'vertical'
        when 'vertical'
          return 'large'
        when 'large'
          return 'small'
      end
    else
      case @size
        when 'small'
          return 'large'
        when 'vertical'
          return 'small'
        when 'large'
          return 'vertical'
      end
    end
  end

  def test_limit(direction)
  # A test to see if the limit of the parent rectangle is on that direction
    case direction
      when 'top'
        if @corners[:top][:left][:x] == 0
          return true
        end
      when 'bottom'
        if @corners[:bottom][:left][:x] == @parent_rectangle.height - 1 # compensating for zero based
          return true
        end
      when 'left'
        if @corners[:bottom][:left][:y] == 0
          return true
        end
      when 'right'
        if @corners[:bottom][:right][:y] == @parent_rectangle.width - 1 # compensating for zero based
          return true
        end
    end
    return false
  end

  def find_with_direction(direction)
    # Returns a rectangle depending on the direction
    # assumes there are no spaces and the other rectangles are perfectly aligned on their edge
    # the only limits are the container itself
    if test_limit(direction)
      return false
    end
    case direction
      when 'top'
        return find_neighbour_with_coordinates({:x => @corners[:top][:left][:x] - 1, :y => @corners[:top][:left][:y]})
      when 'bottom'
        return find_neighbour_with_coordinates({:x => @corners[:bottom][:left][:x] + 1, :y => @corners[:top][:left][:y]})
      when 'left'
        return find_neighbour_with_coordinates({:x => @corners[:bottom][:left][:x], :y => @corners[:top][:left][:y] - 1})
      when 'right'
        return find_neighbour_with_coordinates({:x => @corners[:bottom][:right][:x], :y => @corners[:top][:right][:y] + 1})
    end
    return false
  end

  def grow_small

  end

  def select_needed_to_change
  # Depending on the next size it should be
  # It will try to select other rectangles around it
  # to fullfill its destiny
  #  case next_size
  #  end
  end

end


#container = Rectangle.new(width:1024,height:513,cell_height:171,cell_width:256)


def demo
  container_width = 10
  container_height = 10
  container = Rectangle.new(width:container_width,height:container_height)
  while true
    random_width = (0..container_width).to_a.sample
    random_height = (0..container_height).to_a.sample
    sub_rectangle = Rectangle.new(width: random_width,height: random_height,content: ('a'..'z').to_a.sample)
    if container.insert_rectangle(sub_rectangle)
      container.render
    else
      container = Rectangle.new(width:container_width,height:container_height)
    end
  end
end

def setup_test
  container = Rectangle.new(width:10,height:10)
  sub_rectangle2 = Rectangle.new(width: 7, height: 7, content: 'B')
  sub_rectangle3 = Rectangle.new(width: 10, height: 2, content: 'C')
  sub_rectangle = container.insert_rectangle(sub_rectangle)
  sub_rectangle2 = container.insert_rectangle(sub_rectangle2)
  sub_rectangle3 = container.insert_rectangle(sub_rectangle3)
  container.render
  puts "In test setup"
  yield container, sub_rectangle3
end

def test_insertion
  setup_test do |container,sub_rectangle|
    if sub_rectangle.has_parent?
      puts 'yay got inserted'
    else
      raise 'Test removal failed'
    end
  end
end

def test_removal
  setup_test do |container,sub_rectangle|
    if sub_rectangle.has_parent?
      container.remove_sub_rectangle(sub_rectangle)
      if container.sub_rectangles != []
        raise 'Rectangle couldnt be removed'
      end
      container.render
    end
    puts 'Rectangle Removed succesfully'
  end
end

def test_finding
  setup_test do |container,sub_rectangle|
    if sub_rectangle.has_parent?
      rectangle = container.find_sub_rectangle_with_coordinates({:x => 8,:y => 2})
      unless rectangle
        raise 'Rectangle in x=2, y=0 not found'
      end
      puts 'Found, removing it'
      container.remove_sub_rectangle(rectangle)
      container.render
    end
  end
end

def test_specie
  setup_test do |container,sub_rectangle|
    unless sub_rectangle.sizes.include? sub_rectangle.size
      raise 'No specie!'
    end
    puts sub_rectangle.size
    puts sub_rectangle.next_size
  end
end


def test_finding_limits
  setup_test do |container,sub_rectangle|
    unless sub_rectangle.test_limit('top')
      raise 'Top Limit test gone wrong'
    end
    unless sub_rectangle.test_limit('left')
      raise 'Left Limit test gone wrong'
    end
  end
end

def test_find_neighbour
  setup_test do |container,sub_rectangle|
    unless sub_rectangle.find_with_direction('top')
      raise 'Right neighbour test gone wrong'
    end
    puts sub_rectangle.find_with_direction('top').content
  end
end

def test_suit
  test_insertion
  test_removal
  test_finding_with_coordinates
  test_specie
end

test_find_neighbour
