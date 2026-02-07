FROM ruby:3.2.2
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
RUN apt-get update -qq \
&& apt-get install -y ca-certificates curl gnupg \
&& mkdir -p /etc/apt/keyrings \
&& curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
&& NODE_MAJOR=19 \
&& wget --quiet -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
&& apt-get update -qq \
&& apt-get install -y build-essential libpq-dev nodejs yarn postgresql-client

RUN mkdir /motivation-streaming-app
WORKDIR /motivation-streaming-app

RUN gem install bundler:2.5.23

COPY Gemfile Gemfile.lock ./
COPY yarn.lock ./

RUN bundle install
RUN yarn install

COPY . /motivation-streaming-app

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]