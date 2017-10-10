module Swarm

  # @example The +Map+ Layout
  #   +-------------------------------------------+
  #   |                                           |
  #   | [0,0] [1,0] [2,0] [3,0] [4,0] [5,0] [6,0] |
  #   |                                           |
  #   | [0,1] [1,1] [2,1] [3,1] [4,1] [5,1] [6,1] |
  #   |                                           |
  #   | [0,2] [1,2] [2,2] [3,2] [4,2] [5,2] [6,2] |
  #   |                                           |
  #   | [0,3] [1,3] [2,3] [3,3] [4,3] [5,3] [6,3] |
  #   |                                           |
  #   | [0,4] [1,4] [2,4] [3,4] [4,4] [5,4] [6,4] |
  #   |                                           |
  #   | [0,5] [1,5] [2,5] [3,5] [4,5] [5,5] [6,5] |
  #   |                                           |
  #   | [0,6] [1,6] [2,6] [3,6] [4,6] [5,6] [6,6] |
  #   |                                           |
  #   +-------------------------------------------+
  class Map

    # @macro swarm.map.dimensions
    #   @return [Integer] the +$1+ of the +Map+.

    # @macro swarm.map.dimensions
    attr_reader :width

    # @macro swarm.map.dimensions
    attr_reader :height

    # A 2 dimensional array of tiles.
    def initialize(width, height, tile_width: 1, tile_height: 1)
      @tiles = (0...height).step(tile_height).map.with_index do |console_y, map_y|
        (0...width).step(tile_width).map.with_index do |console_x, map_x|
          Tile.new map_x,
                   map_y,
                   [console_y, console_x] # reversed for Console::setpos
        end
      end

      @height = height / tile_height
      @width = width / tile_width
    end

    include Enumerable

    def each(&block)
      @tiles.each { |row| row.each &block }
    end

    # @return [Tile] a center tile
    def center
      @tiles[height / 2][width / 2]
    end

    # @return [Tile] a random tile
    def sample
      @tiles.sample.sample
    end

    # @param x [Integer]
    # @param y [Integer]
    # @return [Tile]
    def [](x, y)
      @tiles.fetch(y, Array.new)[x]
    end

    # @param x [Integer]
    # @param y [Integer]
    # @param tile [Tile]
    # @return [Tile]
    def []=(x, y, tile)
      @tiles[y] ||= Array.new
      @tiles[y][x] = tile
    end

    # @return [Tile] the last tile (highest +x+ and +y+ value)
    def last
      self[-1, -1]
    end

    def score(key)
      Catalog.fetch :destroyed, key, 0
    end

    def spawn(flag, percent = 0.0)
      total = ((percent.to_f / 100) * count)

      select(&:empty?).sample(total.to_i).each &flag
    end

    # Move a +Tile+ on the +Map+. This movement action causes a chain
    # reaction potentially moving (or killing) tiles down the map in that
    # same direction.
    #
    # It does this by comparing each neighboring pair
    #   tile_1 -> tile_2
    #   tile_2 -> tile_3
    #   tile_3 -> tile_4
    #
    # And follows these rules
    # * empty tiles don't transfer movement
    # * enemies block enemies
    # * players are killed when touching enemies
    # * enemies get squished by players
    # * players get squished by queens
    # * rocks block everything
    #
    # @param tile [Tile]
    # @param direction [Symbol] +:north+, +:south+, +:east+ or +:west+
    # @return [Boolean] +true+ if the +tile+ is moved successfully, +false+ if it is not
    def move(tile, direction)
      tiles = send(direction, tile)
      move = []

      tiles.each_cons(2) do |this, that|
        break               if this.empty?
        # break move.clear    if (tile == this) && this.enemy? && that.empty?
        break move.clear    if this.enemy? && that.enemy?

        break move.clear    if this.egg? && that.enemy?
        break move.clear    if this.enemy? && that.egg?

        break this.destroy! if this.player? && (that.enemy? || that.egg?)
        break that.destroy! if (this.enemy? || this.egg?) && that.player?

        if (this.worker? || this.queen? || this.egg?) && tile.player? && (that.dirt? || that.rock?)
          this.destroy!
          break
        end

        if this.soldier? && tile.player? && that.rock?
          (neighbors(this) - neighbors(tile)).each &:worker!

          this.destroy!
          break
        end

        if this.player? && tile.queen? && !that.empty?
          this.destroy!
          break
        end

        break move.clear if that.rock?

        move << [that, this.type, this.age]
      end

      return if move.empty?

      tile.empty!
      move.each { |t, type, age| t.send(type, age) }
    end

    # Find the closest route from +this+ to +that+ based only on position
    # (ignoring all obstacles between +this+ and +that+).
    #
    # @param this [Tile] origin tile
    # @param that [Tile] destination tile
    # @return [Array<Symbol, ...>] +:north+, +:east+, +:west+ and/or +:south+
    def aggressive_moves(this, that)
      directions = []
      directions << :north if (this.y > that.y) && ((this.y - that.y) < 10)
      directions << :south if (that.y > this.y) && ((that.y - this.y) < 10)
      directions << :west  if (this.x > that.x) && ((this.x - that.x) < 10)
      directions << :east  if (that.x > this.x) && ((that.x - this.x) < 10)
      directions
    end

    # Find "open" (non-blocking) moves for a +worker+ or +soldier+.
    #
    # @see {Map#north}
    # @see {Map#south}
    # @see {Map#east}
    # @see {Map#west}
    #
    # @param tile [Tile] a +worker+ or +soldier+
    # @return [Array<Symbol, ...>] +:north+, +:east+, +:west+ and/or +:south+
    def available_moves(tile)
      %i(north south east west).select do |direction|
        _, neighbor, _ = send(direction, tile)

        next if neighbor.nil?

        neighbor.player? || neighbor.empty? || (tile.queen? && neighbor.dirt?)
      end
    end

    def neighbors(tile)
      [
        [ 0, 1],
        [ 1, 0],
        [ 0,-1],
        [-1, 0],
        # [ 0, 0], <- self
        [ 1, 1],
        [-1,-1],
        [ 1,-1],
        [-1, 1]
      ].map do |x, y|
        self[tile.x + x, tile.y + y]
      end
    end

    def update
      Console.update Catalog.flush(:changed)
    end

    # @macro swarm.map.direction
    #   @see Map#column
    #   @see Map#row
    #   @param tile [Tile]
    #   @return [Array<Tile, ...>] +column+ or +row+ of tiles starting with +tile+ headed $0 until the end of the map

    # @macro swarm.map.direction
    def north(tile)
      tiles = column(tile).reverse
      tiles.rotate(tiles.index tile)
    end

    # @macro swarm.map.direction
    def south(tile)
      tiles = column(tile)
      tiles.rotate(tiles.index tile)
    end

    # @macro swarm.map.direction
    def east(tile)
      tiles = row(tile)
      tiles.rotate(tiles.index tile)
    end

    # @macro swarm.map.direction
    def west(tile)
      tiles = row(tile).reverse
      tiles.rotate(tiles.index tile)
    end

    # @macro swarm.map.axis
    #   @param tile [Tile]
    #   @return [Array<Tile, ...>] the $0 of tiles that the +tile+ resides on

    # @macro swarm.map.axis
    def row(tile)
      @tiles[tile.y]
    end

    # @macro swarm.map.axis
    def column(tile)
      @tiles.map { |row| row[tile.x] }
    end
  end
end
