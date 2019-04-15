module TestCenter
  module Helper
    module MultiScanManager
      class ScanHelper

        attr_reader :can_retry

        def initialize(scan_options: {})
          @scan_options = scan_options
          @can_retry = true
        end
        
        
        def before_all

        end

        def after_each(rescued_build_failure: false)
          if rescued_build_failure
            derived_data_path = File.expand_path(@scan_options[:derived_data_path])
            test_session_logs = Dir.glob("#{derived_data_path}/Logs/Test/*.xcresult/*_Test/Diagnostics/**/Session-*.log")
            test_session_logs.sort! { |logfile1, logfile2| File.mtime(logfile1) <=> File.mtime(logfile2) }
            test_session = File.open(test_session_logs.last)
            backwards_seek_offset = -1 * [1000, test_session.stat.size].min
            test_session.seek(backwards_seek_offset, IO::SEEK_END)
            case test_session.read
            when /Test operation failure: Test runner exited before starting test execution/
              FastlaneCore::UI.message("Test runner for simulator <udid> failed to start")
              @can_retry = true
            when /Test operation failure: Lost connection to testmanagerd/
              FastlaneCore::UI.error("Test Manager Daemon unexpectedly disconnected from test runner")
              FastlaneCore::UI.important("com.apple.CoreSimulator.CoreSimulatorService may have become corrupt, consider quitting it")
              if @scan_options[:quit_core_simulator_service]
                Fastlane::Actions::RestartCoreSimulatorServiceAction.run
                @can_retry = true
              else
                @can_retry = false
              end
            else
              @can_retry = false
            end
          end
        end
      end
    end
  end
end