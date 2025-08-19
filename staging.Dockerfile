FROM ruby:3.3.6
WORKDIR /work
ENV RAILS_ENV=staging
ENV RAILS_LOG_TO_STDOUT=true
RUN apt update -y
RUN apt-get install libvips -y
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash -
RUN apt-get install -y nodejs
# Install Chromium for ferrum and poppler-utils for PDF processing
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    poppler-utils chromium chromium-sandbox fonts-liberation libappindicator3-1 xdg-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt
RUN npm install --global yarn
RUN gem install bundler
COPY Gemfile .
COPY Gemfile.lock .
#COPY package.json .
#COPY yarn.lock .
RUN bundle install
#RUN yarn install
COPY . .
EXPOSE 3000
CMD ["./container-start.sh"]