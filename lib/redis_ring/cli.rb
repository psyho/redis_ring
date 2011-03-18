module RedisRing

  class CLI

    COMMANDS = [:help, :start]

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      command = argv[0]
      if command.nil? || !COMMANDS.include?(command.to_sym)
        usage
        exit(1)
      else
        send(command, *argv[1..-1])
        exit(0)
      end
    end

    protected

    def help
      usage
    end

    def usage
      puts <<USAGE
Usage:
  #{$0} command [arguments]

Commands:
  help - prints this message

  start [config_file] - starts application
USAGE
    end

    def start(config_file = nil)
      config = config_file ? Configuration.from_yml_file(config_file) : Configuration.new

      app = Application.new(config)
      app.start
      app.wait
    end

  end

end
