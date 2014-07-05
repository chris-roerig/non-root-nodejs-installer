require 'rubygems'
require 'nokogiri'
require 'open-uri'

# gives us some terminal colors.
# Thanks to Ivan Black 
# via http://stackoverflow.com/questions/1489183/colorized-ruby-output
class String
  def green;    "\033[32m#{self}\033[0m" end
  def blue;     "\033[34m#{self}\033[0m" end
  def brown;    "\033[33m#{self}\033[0m" end
end

# get the user
user = `whoami`.chomp
puts "Hi #{user}! I will attempt to install NodeJS for you.".blue
puts "Shall we begin? [y|Y]"
continue = gets.chomp.downcase

exit unless %w[y yes].include? continue

# .npmrc contents
npmrc = <<-END
root =    /home/#{user}/.local/lib/node_modules
binroot = /home/#{user}/.local/bin
manroot = /home/#{user}/.local/share/man
END

# create .npmrc file
`echo "#{npmrc}" > $HOME/.npmrc`

# get find latest version of nodejs
dlpage = Nokogiri::HTML(open('http://www.nodejs.org/download'))
links = dlpage.css('a')
dllink = links.each { |a| break a['href'] if a.text =~ /node-v[\d\.]+\.tar\.gz/ }
filename = dllink[dllink.rindex('/') + 1, dllink.size]
version = filename[0, filename.rindex('.tar.gz')]

puts "Downloading latest Node version #{filename}".blue
`wget #{dllink} -P /tmp`

if ! File.exist? "/tmp/#{filename}"
  puts 'Seems like the tar.gz was not downloaded. Is the internet down?'.brown
  puts 'try again later'.brown
  exit
end

puts "Extracting to /tmp".blue
`tar xf /tmp/#{filename} -C /tmp/`

puts "Configuring".blue
%x[cd /tmp/#{version}/ && ./configure --prefix=$HOME/.local]

puts "make-ing (this will take some time)".blue
%x[cd /tmp/#{version} && make 2>&1]

puts "make install".blue
%x[cd /tmp/#{version}/ && make install]

puts "Creating symlink".blue
if ! File.exist? "/home/#{user}/.node_modules"
  `ln -s .local/lib/node_modules $HOME/.node_modules`
end

puts "Updating local PATH".blue
%x[export PATH=$HOME/.local/bin:$PATH]

puts "Updating $HOME/.profile".blue
%x[echo "export PATH=$HOME/.local/bin:$PATH" >> $HOME/.profile]

puts 'Cleaning up...'.blue
%x[cd /tmp && rm -rf #{version}] if File.exist? "/tmp/#{version}"
%x[cd /tmp && rm #{filename}] if File.exist? "/tmp/#{filename}"

if %x[which npm].length > 0 
  puts "Installed Node version: #{%x[node -v]}".chomp.green
  puts "Installed npm version: #{%x[npm -v]}".green.chomp
  puts 'Looks like everything worked. Happy Node-ing'.green
else
  puts 'It looks like there might have been trouble. Try again'.brown
end
