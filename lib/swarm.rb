require 'curses'
require 'io/console'

require 'pry'

$LOAD_PATH.unshift __dir__

require 'swarm/console'
require 'swarm/game'
require 'swarm/map'
require 'swarm/catalog'

require 'swarm/tile'

require 'swarm/level'
require 'swarm/levels/intro'
require 'swarm/levels/one'
require 'swarm/levels/two'
require 'swarm/levels/three'
require 'swarm/levels/four'
require 'swarm/levels/five'

require 'swarm/version'

# Namespace for classes and modules of the +Swarm+ application.
module Swarm

  # Initialize the console, launch the game, play the game, print the
  # scoreboard and exit to the shell.
  #
  # @return [Kernel#exit] exit to shell with success/failure status code
  def self.start
    Signal.trap('INT') { game.stop } # Ctrl-C stops the game gracefully

    game = Game.new

    Console.open do

      game.start

      Level.each do |level|
        next if game.over?

        game.setup! level
        game.show!
        game.play! until game.over? || level.over?
      end

      game.stop
    end

    puts game

    exit true # success!
  rescue => error
    Console.close

    warn 'Swarm encountered an unhandled error'
    warn error.message, *error.backtrace
    exit false # failure!
  end
end
