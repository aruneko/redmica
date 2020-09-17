workers 4

before_fork do
    require 'puma_worker_killer'

    PumaWorkerKiller.config do |config|
        config.ram = (ENV['RAILS_MEMORY_LIMIT'] || 2048).to_i
        config.frequency = 10
        config.percent_usage = 0.8
        config.rolling_restart_frequency = false
        config.reaper_status_logs = ENV['PUMA_KILLER_LOG'] == '1'
    end

    PumaWorkerKiller.start
end
