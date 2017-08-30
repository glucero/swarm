module Swarm

  class Game

    REFRESH_RATE = 0.05 # This seems to keep the laptop under 750°.

    def play!
      turn = Time.now.to_f

      @player = @level.find_player
      @player ||= spawn_player

      listen_for_keypress

      unless @popup
        if (turn - @turn) >= @rate

          @level.play

          @turn = turn
        end

        @level.update
      end

      sleep REFRESH_RATE
    end

    # Set the "start game" flag.
    #
    # @return [true]
    def start
      @status = true

      true
    end

    # Set the "stop game" flag.
    #
    # @return [true]
    def stop
      @status = false

      true
    end

    # @return [Boolean]
    def stopped?
      !@status
    end

    # A game is "over" when any of these conditions are met
    #
    # - the game has been stopped via {Game#stop}
    # - all of the player's lives are gone
    # - all of the invaders are dead
    #
    # @return [Boolean]
    def over?
      stopped? || @players.zero?
    end

    # @return [String]
    def to_s
      <<-TO_S.gsub(/^[ ]{8}/, '') % statistics
                   GAME OVER!

         +  %<eggs>4i x oo (eggs) squished (x20)
         +  %<workers>4i x ├┤ (workers) killed (x20)
         +  %<soldiers>4i x ╟╢ (soldiers) crushed (x50)
         +  %<queens>4i x ╬╬ (queens) defeated (x50)

         -  %<deaths>4i x ◄▶ (players) destroyed (x100)
        -------------------------------
          %<points>6i points
      TO_S
    end

    def pause
      if @popup
        @popup.close
        @popup = false

        @level.update!
      else
        @popup = Console::PopUp.new(yield)
        @popup.refresh
      end
    end

    def setup!(level)
      @level = level
      @level.define_singleton_method(:pause, &method(:pause))

      @popup = false

      @status = true
      @turn   = Time.now.to_f

      @level.setup
    end

    def show!
      @level.update # update the level and refresh the console before displaying anything

      @level.show(@players)
    end

    private

    # @return [Hash]
    def statistics
      Hash.new(0).tap do |stats|
        stats[:eggs]     += Catalog.fetch(:destroyed, :egg, 0)
        stats[:workers]  += Catalog.fetch(:destroyed, :worker, 0)
        stats[:soldiers] += Catalog.fetch(:destroyed, :soldier, 0)
        stats[:queens]   += Catalog.fetch(:destroyed, :queen, 0)
        stats[:deaths]   += Catalog.fetch(:destroyed, :player, 0)
        stats[:points]   +=
          (stats[:eggs]     * 20) +
          (stats[:workers]  * 20) +
          (stats[:soldiers] * 50) +
          (stats[:queens]   * 50) -
          (stats[:deaths]   * 100)
      end
    end

    # # @return [Tile]
    # def find_or_spawn_player
    #   find_player || spawn_player
    # end

    # def find_player
    #   @player = @level.find_player
    # end

    def spawn_player
      @players -= 1

      pause do
        <<-POPUP.gsub(/[ ]{10}/, '') % Console.key_info
                     YOU HAVE BEEN KILLED!
          ----------------------------------------------
          Press %<pause>s to continue.

          (#@players lives remaining)
        POPUP
      end

      @player = @level.spawn_player
    end

    def listen_for_keypress
      Console.keypress do |command|
        case command
        when Console.up;    @popup || @level.move_player(:north)
        when Console.down;  @popup || @level.move_player(:south)
        when Console.left;  @popup || @level.move_player(:west)
        when Console.right; @popup || @level.move_player(:east)
        when Console.pause; pause { 'PAUSED' }
        when Console.quit;  stop
        end
        STDIN.iflush # prevent command queueing
      end
    end

    def initialize
      @players = 5

      @rate = 2.0
    end
  end
end
