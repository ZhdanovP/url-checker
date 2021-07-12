require "./lib/tasks/printer"
require "./lib/tasks/stats_logger"
require "./lib/tasks/status_checker"
require "./lib/tasks/url_generator"
require "./lib/concurrency_util"
require "./lib/config"
require "./lib/diagnostic_logger"

include ConcurrencyUtil

# url generator -> [url] -> worker_0 -> [{url, result}] -. print
#                        \_ worker_1 _/

config = Config.load
logger = DiagnosticLogger.new("main")
interrupt = Channel(Nil).new

Signal::INT.trap do
  logger.info("Shutting down")
  interrupt.send nil
end

url_stream = every(config.period, interrupt: interrupt) {
  logger.info("sending urls")
  Config.load.urls
}

result_stream = StatusChecker.run(url_stream, workers: config.workers)

stats_stream = StatsLogger.run(result_stream)

done = Printer.run(stats_stream)

done.receive?
puts "goodbye"
