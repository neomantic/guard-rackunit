require 'set'
require_relative './notifier'
module Guard
  class RackUnit
    class RunResult

      def self.create(process_status, stdout, stderr)
        if process_status.success?
          Success.new(stdout)
        else
          Failure.new(stderr)
        end
      end

      class Pending
        def issue_notification; end
        def paths; Set[]; end
      end

      class Success

        def initialize(result_io)
          @message = result_io.read
          puts @message
        end

        def issue_notification
          Notifier.new(@message).notify NOTIFY_OPTIONS
        end

        def paths; Set[]; end

        private
        NOTIFY_OPTIONS = {image: :success, priority: -2}.freeze

      end


      class Failure

        def initialize(result_io)
          @failed_paths_set = Set[]
          result_io.each_line do |line|
            puts line # give user some feedback
            match_data = line.match(FAILURE_REGEX)
            unless match_data.nil?
              @failed_paths_set.add(match_data[1])
            else
              # the last line should have the results summary
              @message = line
            end
          end
        end

        def issue_notification
          Notifier.new(@message).notify NOTIFY_OPTIONS
        end

        def paths
          @failed_paths_set || Set[]
        end

        private
        FAILURE_REGEX = /\Alocation:.+path:(.+)>/
        NOTIFY_OPTIONS = {image: :failed, priority: 2}.freeze

      end
    end
  end
end