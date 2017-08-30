module Swarm

  module Console

    module Color
      BLACK  = 234
      SILVER = 240
      WHITE  = 248
      GREY   = 237
      RED    = 167
      PURPLE = 104
      GREEN  = 120
      BLUE   = 39
      YELLOW = 186
    end

    module NormalKey
      def up;    @up    ||= Curses::Key::UP    end
      def down;  @down  ||= Curses::Key::DOWN  end
      def left;  @left  ||= Curses::Key::LEFT  end
      def right; @right ||= Curses::Key::RIGHT end

      def pause; @pause ||= ?\s.freeze end
      def quit;  @quit  ||= ?q.freeze  end
    end

    module VIKey
      def up;    @up    ||= ?k.freeze end
      def down;  @down  ||= ?j.freeze end
      def left;  @left  ||= ?h.freeze end
      def right; @right ||= ?l.freeze end

      def pause; @pause ||= ?\s.freeze end
      def quit;  @quit  ||= ?q.freeze  end
    end

    include Curses
    include Color

    class PopUp < Window

      def initialize(message, indent: 2)
        lines = message.split(?\n)
        height = 2 + lines.count
        max = lines.map(&:length).max
        width = max + (indent*2)

        super height,
              width,
              (Console.height/2) - (height/2),
              (Console.width/2) - (max/2) - indent

        box ?|, ?-, ?+

        lines.each.with_index do |line, index|
          setpos (index + 1), 2
          addstr line.center(max)
        end
      end
    end

    attr_reader :key_info

    extend self

    def init_keys
      nonl
      noecho # don't echo keypresses
      stdscr.nodelay = -1 # don't wait for input, just listen for it
      stdscr.keypad true

      @key_info = {pause: '<SPACEBAR>', quit: ?q}

      if ENV.fetch('SWARM', 'VIM_MODE') == 'easy'
        extend NormalKey

        @key_info.merge! north: '<UP>', south: '<DOWN>', west: '<LEFT>', east: '<RIGHT>'
      else
        extend VIKey

        @key_info.merge! north: ?k, south: ?j, west: ?h, east: ?l
      end
    end

    def init_colors
      start_color
      use_default_colors

                #id     #fg     #bg
      init_pair BLACK,  BLACK,  BLACK
      init_pair SILVER, SILVER, SILVER
      init_pair WHITE,  WHITE,  WHITE
      init_pair GREY,   GREY,   GREY
      init_pair RED,    RED,    BLACK
      init_pair PURPLE, PURPLE, BLACK
      init_pair GREEN,  GREEN,  BLACK
      init_pair BLUE,   BLUE,   BLACK
      init_pair YELLOW, YELLOW, BLACK
    end

    # @yieldparam command [String] yields +command+ on keypress
    def keypress
      command = getch and yield(command)
    end

    # @macro swarm.console.dimensions
    #   @return [Integer] +$0+ of console

    # @macro swarm.console.dimensions
    def width
      @width ||= cols
    end

    # @macro swarm.console.dimensions
    def height
      @height ||= lines
    end

    # Redraw all +tiles+ given and refresh the console
    # @param tiles [Array<Tile, ...>]
    def update(tiles)
      tiles.each &method(:draw)
      refresh
    end

    # @param color [Integer] 0 to 8
    # @param x [Integer]
    # @param y [Integer]
    def draw(tile)
      setpos *tile.location

      attron(color_pair tile.color) { addstr tile.icon }
    end

    def wipe
      clear
      refresh
    end

    # Turn line buffering on and close the +Curses+ session.
    def close
      return if closed?

      nocbreak
      close_screen
    end

    # Initialize the +Curses+ environment, configure it and then clean up
    # when the caller is done. 9 different bg/fg pairs are initialized for
    # the colored +Tile+ squares (0-8): (black, red, green, yellow, blue,
    # magenta, cyan, white, grey)
    def open
      init_screen
      init_colors
      init_keys

      curs_set 0 # hide the cursor
      cbreak # turn off line buffering

      yield

      close
    end
  end
end
