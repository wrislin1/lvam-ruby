#!/bin/bash
set -x
set -e

# Define a function to handle the SIGTERM signal
function graceful_shutdown {
  echo "Received SIGTERM signal. Shutting down gracefully..."
  kill -TERM "$rails_pid"
  wait "$rails_pid"
  echo "Rails server has shut down."
}

# Register the graceful_shutdown function to handle the SIGTERM signal
trap graceful_shutdown SIGTERM

# Start the Rails server
bundle exec rake db:prepare
bundle exec puma -C "config/puma.rb"

rails_pid="$!"

# Wait for the Rails server to exit
wait "$rails_pid"