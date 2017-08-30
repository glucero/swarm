module Swarm
  class Intro < Level
    def play
      @over = true
    end

    def show(*args)
      @over = false
      pause do <<-POPUP.gsub(/[ ]{10}/, '') % Console.key_info
                      Swarm Instructions
          ----------------------------------------------
                      Movement:
                        north: %<north>s
                        south: %<south>s
                        west:  %<west>s
                        east:  %<east>s

                      Pause: %<pause>s
                      Quit:  %<quit>s
          ----------------------------------------------

                      Press %<pause>s to begin.
        POPUP
      end
    end

    def setup
      @map.center.player!
    end

    def over?
      @over
    end
  end
end

