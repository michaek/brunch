path = require "path"
yaml = require "yaml"
fs = require "fs"

brunch = require "./brunch"
helpers = require "./helpers"


generateConfigPath = (appPath) ->
  if appPath? then path.join(appPath, "config.yaml") else "brunch/config.yaml"


loadConfig = (configPath) ->
  try
    options = yaml.eval fs.readFileSync configPath, "utf8"
  catch error
    helpers.logError "[Brunch]: couldn't find config.yaml file"
    helpers.exit()
  options


parseOpts = (options, loadFile = yes) ->
  if loadFile
    config = loadConfig generateConfigPath options.appPath
    options = helpers.extend options, config
  defaults =
    templateExtension: "eco"
    path: "brunch"
    dependencies: []
    minify: no
  helpers.extend defaults, options


log = (text) ->
  process.stdout.write text + "\n"


config =
  commands:
    new:
      help: "Create new brunch project"
      opts:
        appPath:
          position: 1
          help: "application path"
          metavar: "APP_PATH"
          full: "app_path"
        buildPath:
          abbr: "o"
          help: "build path"
          metavar: "DIRECTORY"
          full: "output"
        mvc:
          help: "Set application framework"
          default: "backbone"
          choices: ["backbone", "batman"]
        templates:
          help: "Set templates engine"
          default: "eco"
          choices: ["eco", "jade", "haml"]
        styles:
          help: "Set style engine"
          default: "css"
          choices: ["css", "sass", "compass", "stylus"]  # "sass" == "compass"
        tests:
          help: "Set testing framework"
          default: "jasmine"
          choices: ["jasmine", "nodeunit"]
      callback: (options) ->
        brunch.new (parseOpts options, no), -> brunch.build parseOpts options

    build:
      help: "Build a brunch project"
      opts:
        appPath:
          position: 1
          help: "application path"
          metavar: "APP_PATH"
          full: "app_path"
        buildPath:
          abbr: "o"
          help: "build path"
          metavar: "DIRECTORY"
          full: "output"
        minify:
          abbr: "m"
          flag: yes
          help: "minify the app.js output via UglifyJS"
      callback: (options) ->
        brunch.build parseOpts options

    watch:
      help: "Watch brunch directory and rebuild if something changed"
      opts:
        appPath:
          position: 1
          help: "application path"
          metavar: "APP_PATH"
          full: "app_path"
        buildPath:
          abbr: "o"
          help: "build path"
          metavar: "DIRECTORY"
          full: "output"
        minify:
          abbr: "m"
          flag: yes
          help: "minify the app.js output via UglifyJS"
      callback: (options) ->
        brunch.watch parseOpts options
  
  globalOpts:
    version:
      abbr: "v"
      help: "display brunch version"
      callback: (options) -> log brunch.VERSION

  scriptName: "brunch"

  help: (parser) ->
    str = ""
    str += "commands:\n"
    {commands, script} = parser.usage()
    for name, command of commands
      str += "   #{script} #{command.name}: #{command.help}\n"
    str += """\n
      To get help on individual command, execute `brunch <command> --help`
    """
    str


class CommandParser
  _setUpParser: ->
    parser = require "nomnom"
    for name, data of @config
      switch name
        when "commands"
          for cmdName, cmdData of data
            command = parser.command cmdName
            for attrName, value of cmdData
              command[attrName] value
        else
          data = data parser if typeof data is "function"
          parser[name] data
    parser

  parse: ->
    @_parser.parseArgs()
    log @_parser.getUsage() unless process.argv[2]

  constructor: (@config) ->
    @_parser = @_setUpParser()

exports.run = ->
  (new CommandParser config).parse()

