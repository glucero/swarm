module Swarm
  class Five < Level

    def play
      promoted =
      laid_egg =
      hatched  = false

      Catalog.select(*%i[worker soldier queen egg]).each do |tile|
        tile.age!

        if tile.worker?
          if !promoted && (tile.age % 15).zero?
            tile.soldier!

            promoted = true
          else
            move tile, @player
          end
        elsif tile.queen?
          if !laid_egg && (tile.age % 10).zero?
            move tile, @player
            tile.egg!

            laid_egg = true
          else
            move tile, @player
          end
        elsif tile.egg?
          if !hatched && (tile.age % 5).zero?
            tile.queen!

            hatched = true
          end
        elsif tile.soldier?
          move tile, @player
        end
      end

      true
    end


    def show(players)
      pause do
        <<-POPUP.gsub(/[ ]{10}/, '') % Console.key_info

          - LEVEL 5 -


          Press %<pause>s to start.

          (#{players} lives remaining)
        POPUP
      end
    end

    def setup
      @map.each &:empty!

      @map.spawn :dirt!, 30
      @map.spawn :rock!, 5
      @map.spawn :worker!, 0.5
      @map.spawn :soldier!, 0.15
      @map.spawn :queen!, 0.3
      @map.spawn :egg!, 0.15

      @map.center.player!
    end
  end
end
