# frozen_string_literal: true

module Cloud
  module Sh
    module Helpers
      module Commands

        def command_chain(base)
          CmdChain.new(base)
        end

        class CmdChain
          def initialize(base)
            @cmd = [base]
          end

          def with(val)
            @cmd << val
            self
          end

          def method_missing(name, *args)
            if args.empty?
              @cmd << name.to_s.tr("_", "-")
            elsif args.first.is_a?(TrueClass)
              @cmd << "--#{name.to_s.tr("_", "-")}"
            else
              @cmd << "--#{name.to_s.tr("_", "-")}=#{args.first}"
            end
            self
          end

          def map(*fields)
            execute.lines.map do |line|
              values = line.split.first(fields.size)
              OpenStruct.new(fields.zip(values).to_h)
            end
          end

          def replace_current_process
            exec(@cmd.join(" "))
          end

          def execute
            cloud_sh_exec(@cmd)
          end

          def to_s
            @cmd.join(" ")
          end
        end
      end
    end
  end
end
