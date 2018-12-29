require_relative 'lib/ector-multi'

Gem::Specification.new do |s|
  s.name        = 'ector-multi'
  s.version     = ::Ector::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Grouping multiple DB operations in a single transaction.'
  s.description = 'Grouping multiple DB operations in a single transaction. 100% Inspired by Ecto'
  s.authors     = ['Emiliano Mancuso']
  s.email       = ['emiliano.mancuso@gmail.com']
  s.homepage    = 'http://github.com/emancu/ector-multi'
  s.license     = 'MIT'

  s.files = Dir[
    'README.md',
    'rakefile',
    'lib/**/*.rb',
    '*.gemspec'
  ]

  s.test_files = Dir['test/*.*']

  s.required_ruby_version = '>= 2.2'

  s.add_dependency 'activerecord', '~> 5.2'
  s.add_development_dependency 'protest', '~> 0.6'
  s.add_development_dependency 'sqlite3', '~> 0'
end
