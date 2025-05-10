# Autoload lib/coffee_app directory
Rails.autoloaders.main.ignore(Rails.root.join('lib/assets'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/tasks'))
