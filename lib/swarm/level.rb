module Swarm

  class Level

    def Level.each(&block)
      [Intro, One, Two, Three, Four, Five].each { |level| block.call level.new }
    end

    def update
      @map.update
    end

    def update!
      @map.each(&:change!)
      @map.update
    end

    def find_player
      @player = (@player && @player.player?) ? @player : @map.find(&:player?)
    end

    def spawn_player
      @map.center.player!
    end

    def move_player(direction)
      move find_player, direction
    end

    def move(tile, direction)
      case direction
      when :north, :south, :west, :east
        @map.move(tile, direction)
      else
        available  = @map.available_moves(tile)
        aggressive = @map.aggressive_moves(tile, direction)
        aggressive &= available

        if aggressive.any?
          @map.move tile, aggressive.sample
        elsif available.any?
          @map.move tile, available.sample
        end
      end
    end

    def over?
      !Catalog.select(*%i[worker soldier queen egg]).any?
    end

    def initialize
      @map = Map.new(Console.width, Console.height, tile_width: 2)

      @map.each &:empty!
      @map.update
    end
  end
end
