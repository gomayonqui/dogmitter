# Description:
#   Get harvest status
#
# Commands:
#   harvest status [date]- Get Harvest status


Harvest = require "harvest"
_ = require "underscore"
moment = require "moment"

require "moment-timezone"

usersData = require("../lib/db/harvest_accounts.json")

users = _.chain(usersData)
.sortBy (user) ->
  user.name.charCodeAt()
.map (user) ->
  parts = user.name.split " "
  user.initials = "##{parts[0][0]}#{parts[1]}"
  user.last_entry = {notes: "is not working", hours: 0}
  user.total_hours = 0
  user
.value()

harvest = new Harvest
  subdomain: "hlm"
  email:  process.env["HARVEST_EMAIL"]
  password: process.env["HARVEST_PASSWORD"]
  debug: false

TimeTracking = harvest.TimeTracking

reduceFunction = (total, entry) -> total + entry.hours

orderFunction = (entry) -> entry.updated_at

generateMessage = (user) ->
  "#{user.initials} (#{user.total_hours}) #{user.last_entry.notes.match(/.{1,25}/g)[0]}... (#{user.last_entry.hours})"

onSuccess = (afterDaily, date, res, index) ->
  (error, tasks) ->
    console.log "Success #{index}"

    if error is null && tasks isnt null
      entries = tasks.day_entries
      if entries && entries.length > 0
        entries = _.sortBy entries, orderFunction
        total_hours = _.reduce entries, reduceFunction, 0
        users[index].total_hours = total_hours.toFixed(2)
        users[index].last_entry = _.last entries
    else
      console.log error

    console.log generateMessage(users[index])

    getTimers res, date, index + 1, afterDaily if index + 1 < users.length
    afterDaily()

afterDailyGen = (res) ->
  _.after users.length, ->
    output = []
    _.each users, (user) ->
      output.push generateMessage(user)
    res.send output.join("\n") if res isnt null

getTimers = (res, date, index, afterDaily) ->
  user = users[index]
  TimeTracking.daily date: date, of_user: user.id, onSuccess(afterDaily, date, res, index)

parseDate = (input) ->
  parts = input.split("-")
  new Date Number(parts[0]), Number(parts[1])-1, Number(parts[2])

module.exports = (robot) ->
  robot.hear /harvest status ?(\d{4}-\d{2}-\d{2})?/i, (res) ->
    input = res.match[1]
    date = if input == null || input == undefined then new Date() else parseDate(input)
    getTimers res, date, 0, afterDailyGen(res)
    res.send  "Verifying harvest status #{moment(date).format('MMM Do YY')}, please wait..."
