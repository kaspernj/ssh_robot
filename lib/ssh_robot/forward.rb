class SshRobot::Forward
  attr_reader :open

  def initialize(args)
    @open = true
    @args = args
    @thread = Knj::Thread.new do
      begin
        #args[:session].logger.sev_threshold = Logger::Severity::DEBUG
        if args[:type] == "local"
          @args[:session].forward.local(@args[:host_local], @args[:port_local].to_i, @args[:host], @args[:port_remote].to_i)
        elsif args[:type] == "remote"
          @args[:session].forward.remote_to(@args[:port_local], @args[:host], @args[:port_remote], @args[:host_local])
        else
          raise "No valid type given."
        end

        @args[:session].loop do
          true
        end
      rescue => e
        puts e.inspect
        puts e.backtrace

        @open = false
      end
    end
  end

  def close
    if !@args
      return nil
    end

    @args[:session].close
    @open = false
    @thread.exit
    @args = nil
    @thread = nil
  end
end
