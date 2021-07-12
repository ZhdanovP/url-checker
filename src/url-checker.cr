require "./lib/tasks/printer"
require "./lib/tasks/stats_logger"
require "./lib/tasks/status_checker"
require "./lib/tasks/url_generator"
require "./lib/concurrency_util"
require "./lib/config"
require "./lib/diagnostic_logger"

config = Config.load
logger = DiagnosticLogger.new("main")
url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new
stats_stream = Channel(Array({String, Stats::Info})).new

every(config.period) {
  logger.info("sending urls")
  Config.load.urls >> url_stream
  # UrlGenerator.run("./config.yml", url_stream)
}

config.workers.times {
  StatusChecker.run(url_stream, result_stream)
}

StatsLogger.run(result_stream, stats_stream)

Printer.run(stats_stream)

# url generator -> [url] -> worker_0 -> [{url, result}] -. print
#                        \_ worker_1 _/

sleep

puts "goodbye"
