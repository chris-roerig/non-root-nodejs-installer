require 'fileutils'
require 'nokogiri'
require 'open-uri'
require 'archive'
require 'ruby-progressbar'

# gives us some terminal colors.
# Thanks to Ivan Black 
# via http://stackoverflow.com/questions/1489183/colorized-ruby-output
class String
  def green;    "\033[32m#{self}\033[0m" end
  def blue;     "\033[34m#{self}\033[0m" end
  def brown;    "\033[33m#{self}\033[0m" end
end

progressbar = ProgressBar.create(:format => '%a %B %p%% %t')

# user info
user = ENV['USER']
user_home = ENV['HOME']

# welcome message
puts <<-WELCOME
Hi #{user}! I will attempt to install NodeJS for you.
If this installer fails have a look at:
#{'http://tnovelli.net/blog/blog.2011-08-27.node-npm-user-install.html'.green}
Shall we begin? [y|Y]
WELCOME

continue = gets.chomp.downcase

exit unless %w[y yes].include? continue

##
# Create ~/.npmrc
#
npmrc_path = "#{user_home}/.npmrc"
progressbar.log "Creating #{npmrc_path}".blue
File.open(npmrc_path, 'w') do |file|
  file.puts <<-END
root =    #{user_home}/.local/lib/node_modules
binroot = #{user_home}/.local/bin
manroot = #{user_home}/.local/share/man
END
end
progressbar.progress += 10

##
# Find the latest version of nodejs 
#
node_dl_page = 'http://www.nodejs.org/download'
progressbar.log "Searching for source package from #{node_dl_page}".blue
dlpage = Nokogiri::HTML(open(node_dl_page))
links = dlpage.css('a')
dllink = links.each { |a| break a['href'] if a.text =~ /node-v[\d\.]+\.tar\.gz/ }

# verify we found something to download
unless dllink.to_s.length > 0 
  puts <<-E_NO_DL_LINK
#{'It appears I could not download the NodeJS source package.'.brown}
Make sure you can reach #{node_dl_page.green} with your browser.
Please report bugs here #{'https://github.com/chris-roerig/non-root-nodejs-installer'.green}.
E_NO_DL_LINK
  progressbar.finish
  exit
end
progressbar.progress += 10

# file name info extracted from the downloaded file
filename = dllink[dllink.rindex('/') + 1, dllink.size]
version = filename[0, filename.rindex('.tar.gz')]

# setup some temp file markers
temp_zip_location = "/tmp/#{filename}"
temp_folder_location = "/tmp/#{version}"

##
# Download the source package
#
progressbar.log "Downloading latest Node version #{filename}".blue
File.open(temp_zip_location, 'wb') do |saved_file|
  open("#{dllink}", 'rb') { |read_file| saved_file.write(read_file.read) }
end

# verify the file was downloaded/exists
unless File.exist? temp_zip_location
  puts 'Seems like the tar.gz was not downloaded. Is the internet down?'.brown
  puts 'try again later'.brown
  exit
end
progressbar.progress += 10

# extract source
progressbar.log "Extracting to #{temp_folder_location}".blue
Archive.extract(temp_zip_location, '/tmp')
progressbar.progress += 10

##
#  Compile source
#
progressbar.log 'Compiling source...Hang on to your butts'.blue
FileUtils.cd(temp_folder_location) do
  progressbar.log './configure'
  progressbar.progress += 10
  %x[./configure --prefix=$HOME/.local]

  progressbar.log "make"
  progressbar.progress += 10
  %x[make 2>&1]

  progressbar.log "make install"
  progressbar.progress += 10
  %x[make install 2>&1]

  progressbar.log "Source compiled".green
end

# create symlink
unless File.exist? "#{user_home}/.node_modules"
  progressbar.log "Creating symlink".blue
  FileUtils.ln_s("#{user_home}/.local/lib/node_modules", "#{user_home}/.node_modules")
  progressbar.progress += 10
end

progressbar.log "Updating $PATH".blue
%x[export PATH=$HOME/.local/bin:$PATH]
progressbar.progress += 5

progressbar.log "Updating $HOME/.profile".blue
%x[echo "export PATH=$HOME/.local/bin:$PATH" >> $HOME/.profile]
progressbar.progress += 5

progressbar.log 'Removing temp files'.blue
FileUtils.cd('/tmp') do
  %x[rm -rf #{version}] if File.exist? "/tmp/#{version}"
  %x[rm #{filename}]    if File.exist? "/tmp/#{filename}"
end
progressbar.finish

# output some version info if all looks ok, otherwise SOS
if %x[which npm].chomp.length > 0 
  puts "Installed Node version: #{%x[node -v]}".chomp.green
  puts "Installed npm version: #{%x[npm -v]}".green.chomp
  puts 'Looks like everything worked. Happy Node-ing'.green
else
  puts 'It looks like there might have been trouble. Try again'.brown
end
