class SshRobot
  def initialize(args)
    require "net/ssh"

    @forwards = []
    @args = Knj::ArrayExt.hash_sym(args)
    @args[:port] = 22 if !@args.key?(:port)

    if block_given?
      begin
        yield(self)
      ensure
        self.close
      end
    end
  end

  # Spawns a session if it hasnt already been spawned and returns it.
  def session
    @session = self.session_spawn if !@session
    return @session
  end

  # Spawns a new net-ssh-instance.
  def session_spawn
    return Net::SSH.start(@args[:host], @args[:user], :password => @args[:passwd], :port => @args[:port].to_i)
  end

  # Returns the a shell-session.
  def shell
    return self.session.shell.sync
  end

  def sftp
    @sftp = Net::SFTP.start(@args[:host], @args[:user], @args[:passwd], :port => @args[:port].to_i)
  end

  # Executes a command.
  def exec(command, &block)
    if block
      return self.session.exec!(command) do |channel, stream, line|
        block.call(:channel => channel, :stream => stream, :line => line)
      end
    else
      return self.session.exec!(command)
    end
  end

  # Executes a command as "root" via "sudo". Accepts the "sudo"-password and a command.
  def sudo_exec(sudo_passwd, command)
    result = ""

    self.session.open_channel do |ch|
      ch.request_pty

      ch.exec("sudo #{command}") do |ch, success|
        ch.on_data do |ch, data|
          if data =~ /^\[sudo\] password for (.+):\s*$/
            ch.send_data("#{sudo_passwd}\n")
          else
            result << data
          end
        end
      end
    end

    self.session.loop
    return result
  end

  def file_exists?(filepath)
    result = self.exec("ls #{Strings.UnixSafe(filepath)}").strip
    return true if result == filepath
    return false
  end

  def forward(args)
    Knj::ArrayExt.hash_sym(args)
    args[:type] = "local" if !args[:type]
    args[:session] = self.session_spawn if !args[:session]
    args[:host_local] = "0.0.0.0" if !args[:host_local]
    return SSHRobot::Forward.new(args)
  end

  alias getShell shell
  alias getSFTP sftp
  alias shellCMD exec

  def close
    @session.close if @session
    @session = nil
  end
end
