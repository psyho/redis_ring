module RedisRing

  module BackgroundThread

    def before_run
    end

    def after_halt
    end

    def do_work
    end

    def run
      before_run

      @continue_running = true

      return Thread.new do
        begin
          while continue_running?
            do_work
          end
          after_halt
        rescue SystemExit
          raise
        rescue => e
          puts "Error caught in #{self.class.name}:"
          puts e
          puts e.backtrace.join("\n")
        end
      end
    end

    def continue_running?
      @continue_running
    end

    def halt
      @continue_running = false
    end

  end

end
