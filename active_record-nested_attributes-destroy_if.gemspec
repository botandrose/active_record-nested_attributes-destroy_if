
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/nested_attributes/destroy_if/version"

Gem::Specification.new do |spec|
  spec.name          = "active_record-nested_attributes-destroy_if"
  spec.version       = ActiveRecord::NestedAttributesDestroyIf::VERSION
  spec.authors       = ["Micah Geisel"]
  spec.email         = ["micah@botandrose.com"]

  spec.summary       = "Adds :destroy_if option to accepts_nested_attributes_for"
  spec.description   = "Adds :destroy_if option to accepts_nested_attributes_for, which is basically a stronger version of :reject_if that destroys existing records, too."
  spec.homepage      = "https://github.com/botandrose/active_record-nested_attributes-destroy_if"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">=6.0", "<7.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "byebug"
end
