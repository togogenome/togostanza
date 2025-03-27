FROM ruby:2.7

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY ./ ./
RUN bundle install

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0"]