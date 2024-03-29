puts "****************************"
puts "****************************"
require 'open-uri'
require 'digest/md5'

class LinesController < ApplicationController
  
  def index
  end
  
  def results
    #Get variables
    @selected = params["Sport"].downcase
    @betthreshold = params["Minvol"].to_i
    @percentthreshold = params["Maxpercent"].to_f/100
    
    #download stats
    @site = form_pregame_url(@selected)
    @doc = Nokogiri::HTML(open(@site))
    
    #extract information
    @awayteams = get_away_teams(@doc)
    @awayrotationnumbers = get_away_rotation_numbers(@doc)
    @hometeams = get_home_teams(@doc)
    @homerotationnumbers = get_home_rotation_numbers(@doc)
    @openinglines = get_opening_lines(@doc)
    @homespread = get_home_spreads(@doc)
    @dates     = get_dates(@doc)
    @totalbets = get_game_total_bets(@doc)
    @homepercent = get_home_bet_percentage(@doc)
    @times = get_times(@doc)
    
    #md5
    @MD5 = Array.new
    @hometeams.length.times do |index|
      @MD5 << md5_string("#{@hometeams[index]}+#{@dates[index]}+#{@selected}")
    end
    
    #put MD5 and spread in table
    @RLMindex = Array.new
    @existarray = Array.new
    @CRarray = Array.new
    @MD5.length.times do |i|
      #@exist = Rlm.find(:first, :conditions => {:md5 => @MD5[i]})
      puts @homespread[i]
      if ( @homepercent[i] < @percentthreshold && @totalbets[i] > @betthreshold && @homespread[i] > 0)
        puts "MADE IT!"
        @RLMindex << i
        @linemove = (@openinglines[i].abs - @homespread[i])
        @CRarray << get_cr(@homepercent[i], @totalbets[i], @linemove).to_i
      end
      #elsif (@homespread[i] != 0 && @totalbets[i] > 1000)
      #  Rlm.create(:md5 => @MD5[i], :spread => @homespread[i])
    end
    @count = 0
  end
  
end

def form_pregame_url(option) #turns user option into the url for the stats
  url = "http://www.pregame.com/feeds/sb/default2.aspx?sport=#{option}"
  return url
end

def get_away_teams(doc)
  teams = Array.new
  doc.search('[@title="away-team-name"]/strong').each do |team|
    team = team.inner_html
    teams << team
  end
  return teams
end

def get_home_teams(doc)
  teams = Array.new
  doc.search('[@title="home-team-name"]/strong').each do |team|
    team = team.inner_html
    teams << team
  end
  return teams
end

def get_dates(doc)
  array = Array.new
  doc.search('[@title="game-date"]').each do |team|
    team = team.inner_html
    array << team
  end
  return array
end

def get_away_rotation_numbers(doc)
  array = Array.new
  doc.search('[@title="away-rotation-number"]').each do |team|
    team = team.inner_html
    array << team
  end
  return array
end

def get_home_rotation_numbers(doc)
  array = Array.new
  doc.search('[@title="home-rotation-number"]').each do |team|
    team = team.inner_html
    array << team
  end
  return array
end

def get_game_total_bets(doc)
  array = Array.new
  doc.search('[@title="game-total-bets"]').each do |team|
    team = team.inner_html.to_i
    array << team
  end
  return array
end

def get_home_spreads(doc)
  array = Array.new
  doc.search('[@title="home-spread"]').each do |team|
    team = team.inner_html.to_f
    array << team
  end
  return array
end

def get_opening_lines(doc)
  array = Array.new
  doc.search('[@title="away-opening-line"]').each do |team|
    team = team.inner_html
    team.gsub!("&Acirc;&frac12;", ".5")
    team.gsub!("pk", "0")
    team.gsub!("Poned", "0")
    array << team.to_f
  end
  return array
end

def get_home_bet_percentage(doc)
  array = Array.new
  doc.search('//td/span').each do |team|
    team = team.inner_html
    array << team
  end
  away_percentages = Array.new(array.size / 8){|i| i * 8 + 4}
  array.replace array.values_at(*away_percentages)
  array.map! {|x| x == "<!--0-->" ? "100%" : x}
  array2 = Array.new
  array.each do |i|
    array2 << (i[0..-2].to_i)/100.0
  end
  array = array2
  return array
end

def get_times(doc)
  array = Array.new
  doc.search('//td[@scope="row"]').each do |team|
    team = team.inner_html
    if (team.include? "PM") || (team.include? "AM")
      array << team
    end
  end
  return array
end

def md5_string(string)
  md5 = Digest::MD5.hexdigest(string)
  return md5
end

def get_cr(percValue, volValue, moveValue, percFactor = 1, decimal_to_percent = 100, fixedPerc = 0.30, fixedVol = 1000, volFactor = 1, moveFactor = 10)
  @cr = (((fixedPerc - percValue) * percFactor * decimal_to_percent).round + ((volValue / fixedVol) * volFactor) + (moveValue * moveFactor))
  return @cr
end