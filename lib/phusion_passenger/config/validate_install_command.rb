#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2014 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

PhusionPassenger.require_passenger_lib 'constants'
PhusionPassenger.require_passenger_lib 'config/command'

module PhusionPassenger
module Config

class ValidateInstallCommand < Command
	def self.description
		return "Validate this #{PROGRAM_NAME} installation"
	end

	def self.help
		puts "Usage: passenger-config validate-install"
		puts "Validate this #{PROGRAM_NAME} installation."
	end

	def run
		if @argv[0] == '--help'
			self.class.help
			exit
		elsif @argv.size > 0
			self.class.help
			exit 1
		end

		begin
			require 'rubygems'
		rescue LoadError
		end
		PhusionPassenger.require_passenger_lib 'utils/ansi_colors'
		PhusionPassenger.require_passenger_lib 'platform_info'

		@ok_count = 0
		@fail_count = 0
		check_tools_in_path
		check_no_other_installs_in_path
		exit 1 if @fail_count > 0
	end

private
	def check_tools_in_path
		logn " * Checking whether this #{PROGRAM_NAME} install is in PATH... "
		paths = ENV['PATH'].to_s.split(':')
		if (gem_bindir &&
				File.exist?("#{gem_bindir}/passenger-config") &&
				paths.include?(gem_bindir)
			) || paths.include?(PhusionPassenger.bin_dir)
			log_ok "yes"
		else
			log_fail "no"
			suggest %Q{
				Please add #{PhusionPassenger.bin_dir} to PATH.
				Otherwise you will get "command not found" errors upon running
				passenger-status and other tools.

				Learn more at about PATH at:

				  #{NGINX_DOC_URL}#_the_path_environment_variable
			}
		end
	end

	def gem_bindir
		if defined?(Gem)
			return Gem.bindir
		else
			return nil
		end
	end

	def check_no_other_installs_in_path
		logn " * Checking whether there are no other #{PROGRAM_NAME} installations... "

		paths = ENV['PATH'].to_s.split(':')
		if Process.uid == 0 &&
		   (sudo_user = ENV['SUDO_USER']) &&
		   (bash = PlatformInfo.find_command("bash")) &&
		   PlatformInfo.find_command("sudo")
			# If we were invoked through sudo then we need to check the original user's PATH too.
			output = `sudo -u #{sudo_user} #{bash} -lc 'echo; echo PATH FOLLOWS; echo "$PATH"' 2>&1`
			output.sub!(/.*\nPATH FOLLOWS\n/m, '')
			output.strip!
			paths.concat(output.split(':'))
		end

		paths.delete(gem_bindir)
		paths.delete(PhusionPassenger.bin_dir)
		paths.uniq!

		other_installs = []
		paths.each do |path|
			filename = "#{path}/passenger-config"
			if File.exist?(filename)
				other_installs << filename
			end
		end
		if other_installs.empty?
			log_ok "ok"
		else
			log_fail "not ok"
			suggest %Q{
				Besides this #{PROGRAM_NAME} installation, the following other
				#{PROGRAM_NAME} installations have been detected:

				  #{other_installs.join("\n\t\t\t\t  ")}

				Please uninstall them to avoid confusion or conflicts.
			}
		end
	end

	def logn(message)
		if STDOUT.tty?
			STDOUT.write(Utils::AnsiColors.ansi_colorize(message))
		else
			STDOUT.write(Utils::AnsiColors.strip_color_tags(message))
		end
		STDOUT.flush
	end

	def log(message)
		if STDOUT.tty?
			STDOUT.puts(Utils::AnsiColors.ansi_colorize(message))
		else
			STDOUT.puts(Utils::AnsiColors.strip_color_tags(message))
		end
	end

	def log_ok(message)
		log "<green>#{message}</green>"
		@ok_count += 1
	end

	def log_fail(message)
		log "<red>#{message}</red>"
		@fail_count += 1
	end

	def suggest(message)
		puts
		log reindent(unindent(message), 3)
		puts
	end

	def unindent(text)
		return PlatformInfo.send(:unindent, text)
	end

	def reindent(text, level)
		return PlatformInfo.send(:reindent, text, level)
	end

	def get_paths
		return ENV['PATH'].to_s.split(':')
	end
end

end # module Config
end # module PhusionPassenger
