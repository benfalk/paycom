require 'paycom/version'
require 'net/http'
require 'net/https'
require 'active_support/core_ext'

module Paycom

  class Login

    URL = URI('https://www.paycomonline.net/v4/ee/ee-loginproc.php')
    REFERER = 'https://www.paycomonline.net/v4/ee/ee-login.php'

    def initialize(username,password,pin)
      Paycom.http_start(URL) do |http|
        request = Net::HTTP::Post.new URL.path
        request.set_form_data signon_hash(username,password,pin)
        request['Referer'] = REFERER
        @response = http.request request
      end
    end

    def cookies
      @response.to_hash['set-cookie'].reverse.map { |c| $1 if c=~ /(pcm[=0-9a-zA-Z]*)/ }.join '; '
    end

    private

    def signon_hash(username,password,pin)
      { :username => username, :userpass => password, :userpin => pin, :login => 'Log In >' }
    end

  end

  class Menu

    REFERER = 'https://www.paycomonline.net/v4/ee/ee-menu.php'
    URL = URI(REFERER)
    BASE = 'https://www.paycomonline.net/v4/ee/'

    def initialize(login)
      @login = login
      Paycom.http_start(URL) do |http|
        request = Net::HTTP::Get.new URL.path
        request['Referer'] = REFERER
        request['Cookie'] = login.cookies
        @response = http.request request
      end
    end

    def response
      @response
    end

    def time_sheet_uri
      @time_sheet_uri ||=
        if @response.body =~ /(ee-tawebsheet.php\?[=0-9a-zA-Z&]*)/
          URI("#{BASE}#{$1}")
        else
          raise 'MenuMismatch'
        end
    end

    def time_sheet
      response = nil
      Paycom.http_start(time_sheet_uri) do |http|
        request = Net::HTTP::Get.new "#{time_sheet_uri.path}?#{time_sheet_uri.query}"
        request['Referer'] = REFERER
        request['Cookie'] = @login.cookies
        response = http.request request
      end
      response
    end

    def single_punch_uri
      @single_punch ||=
        if time_sheet.body =~ /(ee-tawebsheet.php\?[=0-9a-zA-Z&_-]*cmdshowaddpunch=1[=0-9a-zA-Z&_-]*)/
          URI("#{BASE}#{$1}")
        else
          raise 'MenuMismatch'
        end
    end

    def single_punch
      response = nil
      Paycom.http_start(single_punch_uri) do |http|
        request = Net::HTTP::Get.new "#{single_punch_uri.path}?#{single_punch_uri.query}"
        request['Referer'] = REFERER
        request['Cookie'] = @login.cookies
        response = http.request request
      end
      response
    end

  end

  class SinglePunch

    URL = URI('https://www.paycomonline.net/v4/ee/ee-tawebsheet.php')

    def initialize(login)
      @login = login
      @single_punch = Menu.new(login).single_punch
      @attrs = {
          punchtype: '',
          'addpunchtime[h]' => '',
          'addpunchtime[i]' => '',
          'addpunchtime[a]' => '',
          punchtaxprof: '0',
          punchdept: '',
          punchdateend: '',
          punchdatestr: ''
      }
    end

    def period_select
      @period_select ||= "#{$1}" if @single_punch.body =~ /periodselect=(\d\d\d\d-\d\d-\d\d_\d\d\d\d-\d\d-\d\d)/
    end

    def clockid
      @clockid ||= "#{$1}" if @single_punch.body =~ /clockid=([a-zA-Z0-9]*)/
    end

    def punch_type=(type); @attrs[:punchtype] = type  end
    def punch_type; @attrs[:punchtype] end

    def punch_time=(time)
      @attrs['addpunchtime[h]'] = time.strftime '%H'
      @attrs['addpunchtime[i]'] = time.strftime '%M'
    end

    def punch_date_start=(date)
      @attrs[:punchdatestr] = date.strftime '%Y-%m-%d'
    end

    def punch_date_end=(date)
      @attrs[:punchdateend] = date.strftime '%Y-%m-%d'
    end

    def punch_dept=(dept)
      @attrs[:punchdept] = dept
    end

    def punch
      items = { periodselect: period_select, clockid: clockid, cmdaddpunch: 'Add Punch >' }
      @attrs.each_pair { |k,v| items["new#{k.to_s}"] = v }
      response = nil
      Paycom.http_start(URL) do |http|
        request = Net::HTTP::Post.new URL.path
        request.set_form_data items
        request['Cookie'] = @login.cookies
        response = http.request request
      end
      response
    end
  end

  class << self

    def http_start(uri)
      Net::HTTP.start uri.host, uri.port, :use_ssl => uri.scheme == 'https' do |http|
        yield http
      end
    end

    def week_punch(login,date)
      punches = {
          'ID' => DateTime.now.beginning_of_day + 8.hours,
          'OL' => DateTime.now.beginning_of_day + 12.hours,
          'IL' => DateTime.now.beginning_of_day + 13.hours,
          'OD' => DateTime.now.beginning_of_day + 17.hours
      }
      single = SinglePunch.new login
      single.punch_date_start = date.beginning_of_week
      single.punch_date_end = date.end_of_week - 2.days
      punches.each_pair do |type,punch_time|
        single.punch_time = punch_time
        single.punch_type = type
        single.punch_dept = type[0] == 'I' ? '103750' : ''
        single.punch
      end
    end

  end

end
