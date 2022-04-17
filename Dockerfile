FROM ruby
WORKDIR /app
ADD . /app
CMD ["ruby", "web/server.rb"]
