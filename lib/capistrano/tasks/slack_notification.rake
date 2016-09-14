require 'faraday'
require 'json'

namespace :slack do
  start = Time.now
  elapsed_time = -> { sprintf('%.2f', Time.now - start) }

  set :slack_token, nil
  set :slack_channel, '#general'

  set :slack_endpoint, 'https://slack.com'
  set :slack_username, 'capistrano'
  set :slack_icon_url, 'https://raw.githubusercontent.com/linyows/capistrano-slack_notification/master/misc/capistrano-icon.png'

  set :slack_deployer, -> {
    username = `git config --get user.name`.strip
    username = `whoami`.strip unless username
    username
  }

  set :slack_post_message_api_endpoint, -> {
    "/api/chat.postMessage?token=#{fetch(:slack_token)}"
  }

  set :slack_channel_list_api_endpoint, -> {
    "/api/channels.list?exclude_archived=1&token=#{fetch(:slack_token)}"
  }

  set :slack_path, -> { fetch(:slack_post_message_api_endpoint) }

  set :slack_stage, -> {
    stage = fetch(:stage)
    stage.to_s == 'production' ? ":warning: #{stage}" : stage
  }

  set :slack_default_body, -> {
    {
      username: fetch(:slack_username),
      channel: fetch(:slack_channel),
      icon_url: fetch(:slack_icon_url),
      text: '',
      link_names: 1,
      mrkdwn: true
    }
  }

  set :slack_start_body, -> {
    text = "Started deploying to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
      " (branch #{fetch(:branch)})"

    build_http_body({
      attachments: [{
        color: "warning",
        title: fetch(:application),
        text: text,
        fallback: text,
        mrkdwn_in: ['text']
      }]
    })
  }

  set :slack_failure_body, -> {
    text = "Failed deploying to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
      " (branch #{fetch(:branch)} at #{fetch(:current_revision)} / #{elapsed_time.call} sec)"

    build_http_body({
      attachments: [{
        color: 'danger',
        title: fetch(:application),
        text: text,
        fallback: text,
        mrkdwn_in: ['text']
      }]
    })
  }

  set :slack_success_body, -> {
    task = fetch(:deploying) ? 'deployment' : '*rollback*'
    text = "Successful #{task} to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
      " (branch #{fetch(:branch)} at #{fetch(:current_revision)} / #{elapsed_time.call} sec)"

    build_http_body({
      attachments: [{
        color: 'good',
        title: fetch(:application),
        text: text,
        fallback: text,
        mrkdwn_in: ['text']
      }]
    })
  }

  set :slack_client, -> {
    Faraday.new(fetch :slack_endpoint) do |c|
      c.request :url_encoded
      c.adapter Faraday.default_adapter

      v = Faraday::VERSION.split('.')
      if v.join('.').to_f >= 0.9
        c.options.timeout = 5
        c.options.open_timeout = 5
      end
    end
  }

  def build_http_body(body)
    if fetch(:slack_token)
      fetch(:slack_default_body).merge(JSON.dump(body))
    else
      JSON.dump(fetch(:slack_default_body).merge(body))
    end
  end

  def post_to_slack_with(body)
    run_locally do
      res = fetch(:slack_client).post fetch(:slack_path), body

      if ENV['DEBUG']
        require 'awesome_print'
        ap body
        ap res
      end
    end
  end

  desc 'Post message to Slack (ex. cap production "slack:post[yo!]")'
  task :post, :message do |t, args|
    attachments = [{ text: args[:message] }]
    post_to_slack_with build_http_body(attachments)
  end

  desc 'Get channel ID by channel name from Slack (ex. cap production "slack:channel[general])"'
  task :channel, :channel_name do |t, args|
    run_locally do
      res = fetch(:slack_client).post fetch(:slack_channel_list_api_endpoint)
      body = JSON.load(res.body)
      channel = body['channels'].find { |ch| ch['name'] == args[:channel_name] }
      puts "##{args[:channel_name]}: #{channel['id']}"
    end
  end

  namespace :deploy do
    desc 'Notify a deploy starting to Slack'
    task :start do
      post_to_slack_with fetch(:slack_start_body)
    end

    desc 'Notify a deploy rollback to Slack'
    task :rollback do
      post_to_slack_with fetch(
        :"slack_#{fetch(:deploying) ? :failure : :success}_body")
    end

    desc 'Notify a deploy finish to Slack'
    task :finish do
      post_to_slack_with fetch(:slack_success_body)
    end
  end
end
