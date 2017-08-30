module Swarm
  class Three < Level

    def play
      promoted = false

      Catalog.select(*%i[worker soldier]).each do |tile|
        tile.age!

        if tile.worker?
          if !promoted && (tile.age % 15).zero?
            tile.soldier!

            promoted = true
          else
            move tile, @player
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

          - LEVEL 3 -


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
      @map.spawn :soldier!, 0.2

      @map.center.player!
    end
  end
end
