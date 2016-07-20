# Description:
#   Create a release pull request on GitHub via hubot.
#
# Configuration:
#   HUBOT_RELEASE_GITHUB_TOKEN # required
#   HUBOT_RELEASE_HEAD # defaults to "master"
#   HUBOT_RELEASE_BASE # defaults to "release"
#   HUBOT_RELEASE_DEFAULT_OWNER
#   HUBOT_RELEASE_TEMPLATE_PATH
#   HUBOT_RELEASE_GITHUB_ENDPOINT # defaults to "https://api.github.com"
#
# Commands:
#   hubot release <owner>/<repository> - Create or update a release pull request
#
# Author:
#   ttskch

slack = require 'hubot-slack'
release = require 'github-pr-release'
_ = require 'underscore'

config =
  token: process.env.HUBOT_RELEASE_GITHUB_TOKEN
  head: process.env.HUBOT_RELEASE_HEAD or 'master'
  base: process.env.HUBOT_RELEASE_BASE or 'release'
  template: process.env.HUBOT_RELEASE_TEMPLATE_PATH
  endpoint: process.env.HUBOT_RELEASE_GITHUB_ENDPOINT or 'https://api.github.com'

doRelease = (owner, repo, msg, robot) ->
  msg.send 'Now processing...'
  release(_.extend({owner: owner, repo: repo}, config))
    .then (pr) ->
      unless robot.adapter instanceof slack.SlackBot
        msg.send "Created release PR for #{owner}/#{repo}: #{pr.html_url}"
      else
        robot.emit 'slack.attachment',
          message: msg.message
          content: [{
            pretext: "Created release pull request for #{process.env.HUBOT_RELEASE_GITHUB_FQDN}"
            color: "good"
            author_name: "#{owner}/#{repo}"
            author_link: "https://#{process.env.HUBOT_RELEASE_GITHUB_FQDN}/#{owner}/#{repo}"
            title: "#{pr.title}"
            title_link: "#{pr.html_url}"
            text: "Pull request is #{process.env.HUBOT_RELEASE_HEAD} to #{process.env.HUBOT_RELEASE_BASE} branch"
            fields: [{
              title: "State"
              value: "#{pr.state}"
              short: true
            }]
            footer: "hubot"
            footer_icon: "https://hubot.github.com/assets/images/layout/hubot-avatar@2x.png"
            ts: msg.message.rawMessage.ts
          }]
    .catch (err) ->
      unless robot.adapter instanceof slack.SlackBot
        msg.send "Error: #{err.message}"
      else
        robot.emit 'slack.attachment',
          message: msg.message
          content: [{
            pretext: "Created release pull request for #{process.env.HUBOT_RELEASE_GITHUB_FQDN}"
            color: "warning"
            author_name: "#{owner}/#{repo}"
            author_link: "https://#{process.env.HUBOT_RELEASE_GITHUB_FQDN}/#{owner}/#{repo}"
            title: "Cannot created PR"
            text: err.message
            fields: [{
              title: "State"
              value: "error"
              short: true
            }]
            footer: "hubot"
            footer_icon: "https://hubot.github.com/assets/images/layout/hubot-avatar@2x.png"
            ts: msg.message.rawMessage.ts
          }]

module.exports = (robot) ->
  robot.respond /release +([^ \/]+)\/([^ \/]+) *$/i, (msg) ->
    owner = msg.match[1]
    repo = msg.match[2]
    doRelease owner, repo, msg, robot

  robot.respond /release +([^ \/]+) *$/i, (msg) ->
    owner = process.env.HUBOT_RELEASE_DEFAULT_OWNER
    repo = msg.match[1]
    doRelease owner, repo, msg, robot if owner
