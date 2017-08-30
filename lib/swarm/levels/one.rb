module Swarm
  class One < Level

    def play
      Catalog.select(:worker).each do |tile|
        move tile, @player
      end

      true
    end

    def show(players)
      pause do
        <<-POPUP.gsub(/[ ]{10}/, '') % Console.key_info

          - LEVEL 1 -

          Press %<pause>s to start.

          (#{players} lives remaining)
        POPUP
      end
    end

    def setup
      @map.each &:empty!

      @map.spawn :dirt!, 30
      @map.spawn :rock!, 5
      @map.spawn :worker!, 0.75

      @map.center.player!
    end
  end
end
