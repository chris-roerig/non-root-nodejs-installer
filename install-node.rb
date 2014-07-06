require 'fileutils'
require 'nokogiri'
require 'open-uri'
require 'archive'
require 'ruby-progressbar'

# Thanks irc #ruby
# havinwood, bricker`LA

# gives us some terminal colors.
# Thanks to Ivan Black 
# via http://stackoverflow.com/questions/1489183/colorized-ruby-output
class String
  def green;    "\033[32m#{self}\033[0m" end
  def blue;     "\033[34m#{self}\033[0m" end
  def brown;    "\033[33m#{self}\033[0m" end
  def red;      "\033[31m#{self}\033[0m" end
end

class NodeInstaller

  def initialize
    # setup progress bar 
    pb_inc = (100 / (self.steps.length + 3)) # the +3 is for the make commands
    @progressbar = ProgressBar.create(format: '%a %B %p%% %t', length: 100)

    # user info
    $USER  = ENV['USER']
    $HOME  = ENV['HOME']

    # used through out the methods
    @filename     = nil
    @version      = nil
    @dllink       = nil
    @temp_zip_location    = nil
    @temp_folder_location = nil

    begin
      self.step_welcome

      steps.each do |step|
        self.send(step)
        @progressbar.progress += pb_inc
      end
    rescue => e
      @progressbar.log e.message
      exit
    end

    @progressbar.finish
  end

  def steps
    %w[
    step_create_npmrc 
    step_find_source 
    step_download_source
    step_extract_source
    step_compile
    step_create_symlink
    step_update_path
    step_update_profile
    step_cleanup
    step_report
    ]
  end

  def step_welcome 
    puts <<-WELCOME
Hi #{$USER}! I will attempt to install NodeJS for you.
If this installer fails have a look at:
#{'http://tnovelli.net/blog/blog.2011-08-27.node-npm-user-install.html'.green}
Shall we begin? [y|Y]
    WELCOME

    continue = gets.chomp.downcase

    raise 'See you next time'.green unless %w[y yes].include? continue
  end

  def step_create_npmrc 
    npmrc_path = "#{$HOME}/.npmrc"
    @progressbar.log "Creating #{npmrc_path}".blue

    File.open(npmrc_path, 'w') do |file| 
      file.puts "root    = #{$HOME}/.local/lib/node_modules"
      file.puts "binroot = #{$HOME}/.local/bin"
      file.puts "manroot = #{$HOME}/.local/share/man"
    end

    error = "Failed to create #{npmrc_path}".red
    raise no_link_error unless File.exist? npmrc_path 
  end

  def step_find_source 
    node_dl_page = 'http://www.nodejs.org/download'
    @progressbar.log "Searching for source package from #{node_dl_page}".blue
    dlpage = Nokogiri::HTML(open(node_dl_page))
    links = dlpage.css('a')
    dllink = links.each { |a| break a['href'] if a.text =~ /node-v[\d\.]+\.tar\.gz/ }

    no_link_error = <<-E_NO_DL_LINK
#{'It appears I could not download the NodeJS source package.'.red}
Make sure you can reach #{node_dl_page.green} with your browser.
Please report bugs here #{'https://github.com/chris-roerig/non-root-nodejs-installer'.green}.
    E_NO_DL_LINK

    raise no_link_error.red unless dllink.to_s.length > 0 

    # file name info extracted from the downloaded file
    @filename = dllink[dllink.rindex('/') + 1, dllink.size]
    @version = @filename[0, @filename.rindex('.tar.gz')]
    @dllink = dllink

    # setup some temp file markers
    @temp_zip_location = "/tmp/#{@filename}"
    @temp_folder_location = "/tmp/#{@version}"
  end

  def step_download_source
    @progressbar.log "Downloading latest Node version #{@filename}".blue

    File.open(@temp_zip_location, 'wb') do |saved_file|
      open("#{@dllink}", 'rb') { |read_file| saved_file.write(read_file.read) }
    end

    error = "Failed to download #{@filename}".red
    raise error unless File.exist? @temp_zip_location
  end

  def step_extract_source
    @progressbar.log "Extracting to #{@temp_folder_location}".blue
    Archive.extract(@temp_zip_location, '/tmp')

    error = "Failed to extract to #{@temp_folder_location}".red
    raise error unless File.exist? @temp_folder_location
  end

  def step_compile
    @progressbar.log 'Compiling source...Hang on to your butts'.blue

    FileUtils.cd(@temp_folder_location) do
      @progressbar.log '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
      @progressbar.log './configure --prefix=$HOME/.local'
      %x[./configure --prefix=$HOME/.local]
      @progressbar.increment

      @progressbar.log "make"
      %x[make 2>&1]
      @progressbar.increment

      @progressbar.log "make install"
      %x[make install 2>&1]
      @progressbar.increment
      @progressbar.log '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'

      @progressbar.log "Source compiled".green
    end
  end

  def step_create_symlink
    sym_destination = "#{$HOME}/.node_modules"
    @progressbar.log "Creating symlink at #{sym_destination}".blue

    unless File.exist? sym_destination
      FileUtils.ln_s("#{$HOME}/.local/lib/node_modules", sym_destination)
    end

    error = "Failed to create symlink at #{sym_destination}".red
    raise error unless File.exist? sym_destination
  end

  def step_update_path
    @progressbar.log "Updating $PATH".blue
    %x[export PATH=$HOME/.local/bin:$PATH]
  end

  def step_update_profile
    @progressbar.log "Updating $HOME/.profile".blue
    %x[echo "export PATH=$HOME/.local/bin:$PATH" >> $HOME/.profile]
  end

  def step_cleanup
    @progressbar.log 'Removing temp files'.blue

    %x[rm #{@temp_zip_location}] if File.exist? @temp_zip_location
    %x[rm -rf #{@temp_folder_location}]  if File.exist? @temp_folder_location

    error = 'Failed removing temp file: '.red

    raise "#{error} #{@temp_zip_location}"    if File.exist? @temp_zip_location
    raise "#{error} #{@temp_folder_location}" if File.exist? @temp_folder_location
  end

  def step_report
    # output some version info if all looks ok, otherwise SOS
    unless %x[which npm].chomp == 'npm not found'
      @progressbar.log "Installed Node version: #{%x[node -v]}".chomp.green
      @progressbar.log "Installed npm version: #{%x[npm -v]}".green.chomp
      @progressbar.log 'Looks like everything worked. Happy Node-ing'.green
    else
      @progressbar.log 'The script finished but it looks like there might have been trouble. Try again'.brown
    end
  end
end

# do work
NodeInstaller.new
