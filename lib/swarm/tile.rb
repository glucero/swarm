module Swarm
  class Tile

    class << self

     # Create methods for setting and testing the +type+ value, change status
     # and console color of every +Tile+.
     #
     # @macro [attach] swarm.tile.attr_type
     #   @method $1
     #     set the +type+ to :$1, the +icon+ to +$2+, the +color+ to $3, the +age+
     #     to $7 and flags the tile to be updated by the +Console+
     #     $0, $1, $2, $3, $4, $5, $6, $7
     #
     #     @param age [Integer]
     #     @return [true]
     #
     #   @method $1!
     #     set the +type+ to :$1, the +icon+ to '$2', the +color+ to $3, the +age+
     #     to 0, and flags the tile to be updated by the +Console+
     #
     #     @param age [Integer]
     #     @return [true]
     #
     #   @method $1?
     #     test the value of +type+
     #     @return [Boolean] +true+ if +type+ is $1, +false+ if it is not
      def attr_type(type, icon: String.new, color: 0)
        define_method(type) do |age|
          change do
            @type  = type
            @icon  = icon
            @color = color
            @age   = age
          end

          self
        end

        define_method("#{type}!") { send type, 0  }

        define_method("#{type}?") { @type == type }
      end
    end

    include Console::Color

    attr_type :empty,   icon: '  '.freeze, color: BLACK
    attr_type :dirt,    icon: '██'.freeze, color: SILVER
    attr_type :rock,    icon: '██'.freeze, color: WHITE
    attr_type :worker,  icon: '├┤'.freeze, color: BLUE
    attr_type :soldier, icon: '╟╢'.freeze, color: RED
    attr_type :queen,   icon: '╬╬'.freeze, color: PURPLE
    attr_type :egg,     icon: 'oo'.freeze, color: YELLOW
    attr_type :player,  icon: '◄▶'.freeze, color: GREEN

    # @macro swarm.tile.position
    #   @return [Integer] the position of the +tile+ on the $1 axis.

    # @macro swarm.tile.position
    attr_reader :x

    # @macro swarm.tile.position
    attr_reader :y

    # @return [Symbol]
    attr_reader :type

    # @return [String]
    attr_reader :icon

    # @return [Integer]
    attr_reader :color

    attr_reader :location

    # @return [Integer]
    attr_reader :age

    # Initialize a +Tile+ with the +x+ and both +y+ positions (+Console+ and +Map+)
    # on the +Console+. Since tiles are 2 characters wide, two sets coordinates
    # are stored: the position in the console (+@location+) and the position
    # on the map (+@x+ and +@y+). All tiles start off as +:empty+.
    #
    # @param map_x [Integer]
    # @param map_y [Integer]
    # @param console_x [Integer] default +x+
    # @param console_y [Integer] default +y+
    def initialize(map_x, map_y, location)
      @location = location
      @x = map_x
      @y = map_y
      @age = 0
    end

    def inspect
      '#<%s:0x%014x @x=%p, @y=%p, @type=%p>' % [self.class, object_id << 1, @x, @y, @type]
    end

    # @return [Boolean]
    def ===(other)
      type == other.type
    end

    # @return [Integer]
    def born!
      @age = 0
    end

    # @return [Integer]
    def age!
      @age += 1
    end

    # @return [Boolean]
    def enemy?
      worker? || soldier? || queen?
    end

    # @return [Boolean]
    def mover?
      player? || queen?
    end

    # @return [Void]
    def change
      Catalog.delete type, self

      yield

      Catalog.store type, self
      Catalog.store :changed, self
    end

    def changed?
      Catalog.fetch :changed, self, false
    end

    def change!
      Catalog.store :changed, self
    end

    def destroy!
      Catalog.increment :destroyed, type

      empty!
    end
  end
end
