require "./lib/tasks/printer"
require "./lib/tasks/stats_logger"
require "./lib/tasks/status_checker"
require "./lib/tasks/url_generator"
require "./lib/concurrency_util"

WORKERS = 2
url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new
stats_stream = Channel(Array({String, Stats::Info})).new

every(2.seconds) {
UrlGenerator.run("./urls.yml", url_stream)
}

WORKERS.times {
  StatusChecker.run(url_stream, result_stream)
}

StatsLogger.run(result_stream, stats_stream)

Printer.run(stats_stream)

# url generator -> [url] -> worker_0 -> [{url, result}] -. print
#                        \_ worker_1 _/

sleep

puts "goodbye"
