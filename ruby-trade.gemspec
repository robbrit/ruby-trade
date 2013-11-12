Gem::Specification.new do |s|
  s.name = "ruby-trade"
  s.version = "0.4"
  s.date = "2013-11-09"
  s.summary = "A stock market simulation game."
  s.description = ""
  s.authors = ["Rob Britton"]
  s.email = "rob@robbritton.com"
  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.license = "MIT"

  s.add_runtime_dependency "em-zeromq"
end
