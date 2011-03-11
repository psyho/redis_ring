if File.directory?("/proc")
  class Daemons::Pid

    def self.running?(pid)
      return File.exist?("/proc/#{pid}")
    end

  end
end
