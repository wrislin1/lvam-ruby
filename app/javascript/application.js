// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "flowbite"
import "toastify-js"
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

import "src/streams"
