require 'faraday'
require 'json'

namespace :slack do
  start = Time.now
  elapsed_time = -> { sprintf('%.2f', Time.now - start) }

  set :slack_token, nil
  set :slack_channel, '#general'

  set :slack_endpoint, 'https://slack.com'
  set :slack_username, 'capistrano'
  set :slack_icon_url, 'https://github.com/linyows/capistrano-slack_notification/misc/capistrano-icon.png'

  set :slack_deployer, -> {
    username = `git config --get user.name`.strip
    username = `whoami`.strip unless username
    username
  }

  set :slack_path, -> {
    token = fetch(:slack_token)
    "/api/chat.postMessage#{"?token=#{token}" if token}"
  }

  set :slack_stage, -> {
    stage = fetch(:stage)
    stage.to_s == 'production' ? ":warning: #{stage}" : stage
  }

  set :slack_default_body, -> {
    {
      username: fetch(:slack_username),
      channel: fetch(:slack_channel),
      icon_url: fetch(:slack_icon_url),
      text: ''
    }
  }

  set :slack_start_body, -> {
    fetch(:slack_default_body).merge(
      attachments: JSON.dump([{
        color: "warning",
        title: fetch(:application),
        text: "Started deploying to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
          " (branch #{fetch(:branch)})",
        mrkdwn_in: ['text']
      }])
    )
  }

  set :slack_failure_body, -> {
    fetch(:slack_default_body).merge(
      attachments: JSON.dump([{
        color: 'danger',
        title: fetch(:application),
        text: "Failed deploying to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
          " (branch #{fetch(:branch)} at #{fetch(:current_revision)} / #{elapsed_time.call} sec)",
        mrkdwn_in: ['text']
      }])
    )
  }

  set :slack_success_body, -> {
    task = fetch(:deploying) ? 'deployment' : '*rollback*'
    fetch(:slack_default_body).merge(
      attachments: JSON.dump([{
        color: 'good',
        title: fetch(:application),
        text: "Successful #{task} to #{fetch(:slack_stage)} by @#{fetch(:slack_deployer)}" +
          " (branch #{fetch(:branch)} at #{fetch(:current_revision)} / #{elapsed_time.call} sec)",
        mrkdwn_in: ['text']
      }])
    )
  }

  def post_to_slack(message = '')
    notify_to_slack_with(title: message)
  end

  def post_to_slack_with(body)
    conn = Faraday.new(fetch :slack_endpoint) do |c|
      c.request :url_encoded
      c.adapter Faraday.default_adapter
      c.options.timeout = 5
      c.options.open_timeout = 5
      c.response :logger
    end

    require 'awesome_print'
    res = conn.post fetch(:slack_path), body
    ap body
    ap res
  end

  desc 'Post message to Slack (ex. cap production "slack:notify[yo!])"'
  task :post, :message do |t, args|
    post_to_slack args[:message]
  end

  desc 'Notify a deploy starting to Slack'
  task :notify_start do
    post_to_slack_with fetch(:slack_start_body)
  end

  desc 'Notify a deploy rollback to Slack'
  task :notify_rollback do
    post_to_slack_with fetch(
      :"slack_#{fetch(:deploying) ? :failure : :success}_body")
  end

  desc 'Notify a deploy finish to Slack'
  task :notify_finish do
    post_to_slack_with fetch(:slack_success_body)
  end
end
