# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "stimulus-use" # @0.52.3
pin "flowbite" # @3.1.2
pin "@popperjs/core", to: "popper-lib-2024.js"
pin "flowbite-datepicker" # @1.3.2
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/src", under: "src", to: "src"
pin "toastify-js" # @1.12.0
pin "@rails/activestorage", to: "@rails--activestorage.js" # @8.0.200
