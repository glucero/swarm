require File.join(__dir__, 'lib/swarm/version')

Gem::Specification.new do |gem|
  gem.name          = 'swarm'
  gem.version       = Swarm::VERSION

  gem.author        = 'Gino Lucero'
  gem.email         = 'glucero@gmail.com'

  gem.description   = 'Squish or be squished!'
  gem.summary       = gem.description

  gem.homepage      = 'https://github.com/glucero/swarm'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split(?\n)
  gem.executables   = [gem.name]

  gem.add_dependency 'curses'

  gem.post_install_message = "Usage: 'swarm' or 'SWARM=easy swarm'"

  gem.required_ruby_version = '>= 2.0.0'
end
