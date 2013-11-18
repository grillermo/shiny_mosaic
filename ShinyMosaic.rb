
class Shinymosaic
  attr_accessor :width, :height, :content, :corners, :grid, :parent_rectangle, :sub_rectangles, :space_left, :cell_width, :cell_height, :objects, :object

  def initialize(objects: [],width: 1, height: 1, cell_width: 1, cell_height: 1, content: 0, object: nil)
    @objects = objects
    @object = object
    @cell_width = cell_width
    @cell_height = cell_height
    @width = width / cell_width
    @height = height / cell_height
    @content = content
    @corners = {:top => {:left => {:x=>0,:y=>0},:right => {:x=>0,:y=>0}},
                :bottom => {:left => {:x=>0,:y=>0},:right => {:x=>0,:y=>0}},
                }
    @sub_rectangles = []
    @parent_rectangle = nil
    @space_left = calculate_space_left
    if @width > 1 && @height > 1
      @grid = self.build_grid
    end
  end

  def self.create(objects: [],width: 1280, height: 513, cell_height: 171, cell_width: 256)
    container = Shinymosaic.new(objects: objects, width: width,height:height,cell_height:cell_height,cell_width:cell_width)
    container.mutate_layout
    return container
  end

  def mutate_layout
    @sub_rectangles = []
    @grid = self.build_grid
    @space_left = calculate_space_left
    while @space_left != 0
      object = @objects.to_a.sample
      width = object.width
      height = object.height
      content = object.content
      rectangle = Shinymosaic.new(objects: [],width: width,height: height, content: content,object: object)
      self.insert_rectangle(rectangle)
    end
  end

  def tiles
    @sub_rectangles
  end

  def photo_url
    @object.photo_url
  end

  def id
    self.object_id
  end

  def calculate_space_left
    @width * @height
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
        row.push Shinymosaic.new(content: @content)
      end
      grid.push row
    end
    grid
  end

  def enough_space_below(starting_row,right_y_corner,rectangle)
    # Test if below there is enough space to acomodate our rectangle

    available_height = 0

    # We need the limits with +1 because the coordinates are 0 based and the widths are not
    ending_row = starting_row + (rectangle.height)
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
    for row in @grid[starting_row..ending_row] do
        # we are on the rows that could have enough space
        y = 0
        # Flag to determine if this row has enough space
        row_clean = false
        for cell in row[left_y_corner..right_y_corner] do
          # We are on the cell that could have enough space
          if cell.empty
            # so this row has as least one cell with content
            row_clean = true
          else
            clean_rows = 0
            row_clean = false
          end
          y += 1
        end
        if row_clean
          clean_rows += 1
        end
        if clean_rows >= rectangle.height
          return true
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

  def build_and_insert_rectangle(width: 1, height: 1, content: '1')
    rectangle = Shinymosaic.new(width: width, height: height, content: content)
    return self.insert_rectangle(rectangle)
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
          @space_left -= 1
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
    @sub_rectangles.each do |rectangle|
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

  def test_limit(direction)
  # A test to see if the limit of the parent rectangle is on that direction
    case direction
      when :top
        if @corners[:top][:left][:x] == 0
          return true
        end
      when :bottom
        if @corners[:bottom][:left][:x] == @parent_rectangle.height - 1 # compensating for zero based
          return true
        end
      when :left
        if @corners[:bottom][:left][:y] == 0
          return true
        end
      when :right
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
      when :top
         return find_neighbour_with_coordinates({:x => @corners[:top][:left][:x] - 1, :y => @corners[:top][:left][:y]}),
                find_neighbour_with_coordinates({:x => @corners[:top][:right][:x] - 1, :y => @corners[:top][:right][:y]})
      when :bottom
        return find_neighbour_with_coordinates({:x => @corners[:bottom][:left][:x] + 1, :y => @corners[:top][:left][:y]}),
               find_neighbour_with_coordinates({:x => @corners[:bottom][:right][:x] + 1, :y => @corners[:top][:right][:y]})
      when :left
        return find_neighbour_with_coordinates({:x => @corners[:top][:left][:x], :y => @corners[:top][:left][:y] - 1}),
               find_neighbour_with_coordinates({:x => @corners[:bottom][:left][:x], :y => @corners[:bottom][:left][:y] - 1})
      when :right
        return find_neighbour_with_coordinates({:x => @corners[:top][:right][:x], :y => @corners[:top][:right][:y] + 1}),
               find_neighbour_with_coordinates({:x => @corners[:bottom][:right][:x], :y => @corners[:bottom][:right][:y] + 1})
    end
    return false
  end

  def select_random_sub_rectangle
    @sub_rectangles.sample
  end


  def neighbours
    {:right => self.find_with_direction(:right),
     :left => self.find_with_direction(:left),
     :top => self.find_with_direction(:top),
     :bottom => self.find_with_direction(:bottom)}
  end

  def unique_neighbours
    result = {}
    self.neighbours.each do |direction,findings|
      next if !findings
      unless result.include? direction
        result[direction] = []
      end
      findings.each do |neighbour|
        if neighbour and !result[direction].include? neighbour
          result[direction].push neighbour
        end
      end
    end
    return result
  end

  def left
    @corners[:top][:left][:y] * parent_rectangle.cell_width
  end

  def top
    @corners[:top][:left][:x] *  parent_rectangle.cell_height
  end

  def width_in_pixels
    width = @width * parent_rectangle.cell_width
    if width == 0
      width = parent_rectangle.cell_width
    end
    width
  end

  def height_in_pixels
    height = @height * parent_rectangle.cell_height
    if height == 0
      height = parent_rectangle.cell_height
    end
    height
  end

end




def demo
  container_width = 10
  container_height = 10
  container = Shinymosaic.new(width:container_width,height:container_height)
  while true
    random_width = (0..container_width).to_a.sample
    random_height = (0..container_height).to_a.sample
    sub_rectangle = Shinymosaic.new(width: random_width,height: random_height,content: ('a'..'z').to_a.sample)
    if container.insert_rectangle(sub_rectangle)
      container.render
    else
      container = Shinymosaic.new(width:container_width,height:container_height)
    end
  end
end

def setup_test
  container = Shinymosaic.new(width:1024,height:513,cell_height:171,cell_width:256)
  sub1 = container.build_and_insert_rectangle(width: 1, height: 1, content:'a')
  sub1 = container.build_and_insert_rectangle(width: 1, height: 1, content:'a')
  sub1 = container.build_and_insert_rectangle(width: 1, height: 2, content:'A')
  sub2 = container.build_and_insert_rectangle(width: 1, height: 1, content:'B')
  sub4 = container.build_and_insert_rectangle(width: 2, height: 2, content:'D')
  sub3 = container.build_and_insert_rectangle(width: 1, height: 2, content:'C')
  sub5 = container.build_and_insert_rectangle(width: 1, height: 1, content:'E')
  sub6 = container.build_and_insert_rectangle(width: 1, height: 1, content:'F')
  sub7 = container.build_and_insert_rectangle(width: 1, height: 1, content:'G')
  container.render
  #yield container, sub1, [sub1,sub2, sub3, sub4, sub5, sub6, sub7]
  yield container
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
      if container.sub_rectangles.include? sub_rectangle
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
      rectangle = container.find_sub_rectangle_with_coordinates({:x => 2,:y => 2})
      unless rectangle
        raise 'Rectangle in x=2, y=0 not found'
      end
      puts 'Found, removing it'
      container.remove_sub_rectangle(rectangle)
      container.render
    end
  end
end

def test_finding_limits
  setup_test do |container,sub_rectangle|
    unless sub_rectangle.test_limit(:top)
      raise 'Top Limit test gone wrong'
    end
    unless sub_rectangle.test_limit(:left)
      raise 'Left Limit test gone wrong'
    end
  end
end

def test_find_neighbour
  setup_test do |container,sub_rectangle|
    unless sub_rectangle.find_with_direction(:bottom)
      raise 'Right neighbour test gone wrong'
    end
    puts sub_rectangle.find_with_direction(:bottom).content
  end
end

def test_neighbours
  setup_test do |container,sub_rectangle,all_sub_rectangles|
    all_sub_rectangles.each do |sub_rectangle|
      sub_rectangle.unique_neighbours.each do |direction,neighbours|
        neighbours.each do |neighbour|
          puts "#{sub_rectangle.content} to the #{direction} #{neighbour.content}"
        end
      end
    end
  end
end

def test_mutating
  setup_test do |container|
    container.mutate_layout
    puts container.render_html
  end
end

def test_suit
  test_insertion
  test_finding
  test_removal
  test_finding_limits
  test_specie
  test_find_neighbour
  puts 'all tests ran without problems'
end

