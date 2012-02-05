#!/usr/bin/ruby

# Mutation testing driver. Supports C++, Java, Ruby, and Python.
# Copyright (C) 2010 Jonas Arvidsson

require 'fileutils'
require 'benchmark'
require 'timeout'
require 'English' # $MATCH

TEST_SUITE_PASSED =
  Regexp.new ['^OK \(\d+( tests?)?\)',                            # C++, Java
              '^\d+ tests, \d+ assertions, 0 failures, 0 errors', # Ruby
              '^BUILD SUCCESSFUL',                                # Ant
              'SUCCESS! Test run passed\.',                       # Autotest
              '^OK$'].join('|')                                   # Python

TEST_SUITE_FAILED =
  Regexp.new ['^(?i:failures) ?!!!',                   # C++, Java
              '^  \d+\) (Failure|Error):',             # Ruby
              'There were test failures\.',            # Ant
              'FAILURE! Test run failed\.',            # Autotest
              '^FAILED.*(failures|errors)='].join('|') # Python

Comment = '//[^\n]*|/\*.*?\*/|\#[^\n]*'

SPLITTERS = {
  /.*/ => %r'\s+|
             #{Comment}|
             "[^"\\]*["\\]*"|\'[^\'\\]*[\'\\]*\'|
             0x[0-9A-Fa-f]+|\d[\d_.]*|                # numbers
             class\s+\w+\s*<|=>|                      # avoid mutating < or >
             if\s*\(?|
             (?:return\s*)?(?i:true|false)\b|
             return(?:[^;]*;|\s\S+)|
             [\w@\$][\S]+\s*=\s*[^>=\d\s][^;\n]*;?|   # assignment statements
             [+-]=|
             \w+|
             .'mx,

  /\.rb$/ => %r'\s+|
             #{Comment}|
             0x[0-9A-Fa-f]+|\d[\d_.]*|                # numbers
             class\s+\w+\s*<|=>|                      # avoid mutating < or >
             \w+|
             [\w\d#\s]+|
             .'mx,

  /\.(java|c|cc|cpp|h|hh|hpp)$/ => %r'\s+|
                                      #{Comment}|
                                      [^;{}]+[;{}]|   # statements
                                      \w+|
                                      .'mx
}

DO_NOT_MUTATE = /^\w*(?i:assert)[^;]*;$/

class Progress < Struct.new :total, :start_time
  @@width = 0

  def self.width() @@width end

  def step
    @current = (@current || 0) + 1
  end

  def print_info
    info = '%s %d/%d = %d%% done, %s/%s remaining'
    format = if ENV['TERM'] == 'xterm'
               "\r#{info}   \b\b\b"
             else
               "#{info}\n"
             end
    elapsed   = (Time.now - start_time).to_f
    remaining = (total - @current) * elapsed / @current
    bar_length = 20
    bar = '=' * (1.0 * bar_length * elapsed / (elapsed + remaining)).round
    bar += '-' * (bar_length - bar.size)
    s = sprintf(format, bar,
                @current, total, (100.0 * @current / total).round,
                time_string(remaining),
                time_string(elapsed + remaining))
    print s
    @@width = s.length
    $stdout.flush
  end

  private

  def time_string(sec)
    result, sec = part '',     sec, "h", 3600
    result, sec = part result, sec, "m", 60
    result += "#{sec.round}s" if result !~ /h/
    result
  end

  def part(result, sec, kind, divider)
    n = (sec / divider).floor
    if n > 0
      result += "#{n}#{kind}"
      sec -= divider * n
    end
    [result, sec]
  end
end

class TestSuite < Struct.new :run_cmd
  def run
    if RUBY_PLATFORM == 'java'
      # @todo See http://jira.codehaus.org/browse/JRUBY-4443 for possible
      #       workaround.
      raise "JRuby not supported because of a problem with timeout handling"
    end

    if @run_time
      seconds = 3 + 3 * @run_time
      `(#{File.dirname(__FILE__)}/cmdtimeout -t #{seconds} #{run_cmd}) 2>&1`
    else
      # When we run the tests before mutations, @run_time is still nil, so we
      # don't do any timeout handling. This should be okay. The test suite
      # shouldn't hang before mutations have been applied.
      `(#{run_cmd}) 2>&1`
    end
  end

  def check(what_time)
    @run_time = Benchmark.realtime {
      result = run
      if result !~ TEST_SUITE_PASSED
        $stderr.puts "Test fails #{what_time}", result
        exit 1
      end
    }
  end
end

class Table < Hash
  attr_writer :file_name

  Keywords = Struct.new :null, :true, :false, :and, :or, :pass

  # Iterates over an array of the different ways we can replace the given chunk
  # of code.
  def store_mutations(chunk, pos)
    return if DO_NOT_MUTATE =~ chunk
    kw = Keywords.new *case @file_name
                       when /\.java$/ then %w'null true false &&  || ;'
                       when /\.rb$/   then %w'nil  true false &&  || nil'
                       when /\.py$/   then %w'None True False and or pass'
                       else                %w'0    true false &&  || ;'
                       end
    replacements =
      case chunk
      when /^((?:return\s*)?)(true|false)$/i
        $1 + { kw[:true] => kw[:false], kw[:false] => kw[:true],
               'TRUE' => 'FALSE', 'FALSE' => 'TRUE' }[$2]

      when /^return\s*(\S[^;]*)(;?)/
        semi = $2
        ["return 1 + #$1#{semi}", "return #{kw[:null]}#{semi}"]
      when /^if \s*\(?$/
        ["#$MATCH#{kw[:false]} #{kw[:and]} ",
         "#$MATCH#{kw[:true]} #{kw[:or]} "]

      when /^0x[a-f0-9]+$/i             then "0x%x" % (Integer($MATCH) + 1)
      when /^\d+\.\d+$/                 then $MATCH.to_f + 0.1
      when /^\d[\d_]*$/                 then 101 * $MATCH.to_i / 100 + 1
      when '+='                         then '-='
      when '-='                         then '+='
      when '<'                          then '>'
      when '>'                          then '<'
      when /^("?)([\S]+\s*=\s*)[^;\n]+?([;"]?)$/
        [$1 + kw[:pass] + $3, "#$1#$2#{kw[:null]}#$3", "#$1#{$2}0#$3"]
      when /^\w.+;$/                    then ''
      end
    replacements = [replacements].compact unless Array === replacements
    replacements.reject! { |r|
      r == chunk or (has_key?(pos)             &&
                     self[pos].has_key?(chunk) &&
                     self[pos][chunk].member?(r))
    }
    unless replacements.empty?
      self[pos] ||= Hash.new []
      self[pos][chunk] += replacements
    end
  end
end

class FileMutator
  def self.test_suite=(ts) @@test_suite = ts end
  def self.test_suite()    @@test_suite      end
  def self.progress=(pr)   @@progress = pr   end

  @@stats = Hash.new 0

  def self.process(fm)
    FileUtils.cp fm.file_name, "#{fm.file_name}.orig"
    begin
      fm.run
    ensure
      FileUtils.mv "#{fm.file_name}.orig", fm.file_name
      fm.make_sure_file_is_the_newest
    end
  end

  def self.print_statistics
    print "\n#{@@stats.values.inject do |v,acc| v+acc end || 0} mutations: "
    print [:caught, :missed, :bad].map { |key| "#{@@stats[key]} #{key}" }.
      join(', ')
    good = @@stats[:caught] + @@stats[:missed]
    print ": #{(100.0 * @@stats[:caught] / good).round}% testing" if good != 0
    puts
  end

  attr_reader :file_name
  
  def initialize(file_name, target)
    @file_name, @target = file_name, target
  end

  def nr_of_mutations
    @text  = IO.read @file_name
    @table = Table.new
    @table.file_name = @file_name
    applicable_splitters.each { |chunk_regex|
      pos = 0
      @text.scan(chunk_regex) { |chunk|
        @table.store_mutations chunk, pos
        pos += chunk.length
      }
    }
    @table.values.map { |h| h.values }.flatten.size
  end

  def run
    applicable_splitters.each { |chunk_regex|
      # Split the source code file into chunks that are easy to process in
      # Hash#store_mutations().
      pos = 0
      @text.scan(chunk_regex) { |chunk|
        if @table.has_key?(pos) and @table[pos].has_key?(chunk)
          @table[pos][chunk].each { |replacement|
            File.open(@file_name, 'w') { |f|
              f << @text[0...pos] << replacement << @text[pos+chunk.length..-1]
            }
            make_sure_file_is_the_newest
            line_nr = @text[0...pos].count("\n") + 1
            report @@test_suite.run, chunk, replacement, line_nr
            @@progress.step
            @@progress.print_info
          }
          @table[pos][chunk].clear # only apply each mutation once
        end
        pos += chunk.length
      }
    }
  end

  # Solves the problem of mutated files having the exact same modification time
  # as compiled targets. To make the build process work, we make sure it has a
  # newer time stamp.
  def make_sure_file_is_the_newest
    if @target and File.exist? @target
      until File.mtime(@file_name) > File.mtime(@target)
        if $log_file
          $log_file.puts "Waiting for #{@file_name} to be newer than #{@target}"
        end
        sleep 0.5
        FileUtils.touch @file_name
      end
    end
  end

  private

  def applicable_splitters
    SPLITTERS.map { |name_regex, chunk_regex|
      chunk_regex if @file_name =~ name_regex
    }.compact
  end

  class Message < Struct.new :file_name, :line_nr, :orig, :replacement
    def write(stream, verdict)
      stream.print "\r" if ENV['TERM'] == 'xterm'
      s = ("#{file_name}:#{line_nr}: #{verdict}: Changed '#{orig}' to " +
           "'#{replacement}'")
      stream.print s
      if ENV['TERM'] == 'xterm'
        sticking_out = Progress.width - s.length
        if sticking_out > 0
          stream.print " " * sticking_out + "\b" * sticking_out
        end
      end
      stream.print "\n"
    end

    def write_and_log(verdict)
      write $stdout, verdict
      log verdict
    end

    def log(verdict)
      write $log_file, verdict if $log_file
    end
  end

  def report(result, chunk, replacement, line_nr)
    message = Message.new @file_name, line_nr, chunk, replacement
    $log_file.puts result if $log_file
    key = case result
          when TEST_SUITE_FAILED then :caught
          when TEST_SUITE_PASSED then :missed
          else                        :bad
          end
    @@stats[key] += 1
    case key
    when :caught then message.log 'OK'
    when :missed then message.write_and_log 'Missing test'
    when :bad    then message.log 'Bad mutation'
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  def usage
    program = File.basename $PROGRAM_NAME
    $stderr <<
      "Usage: #{program} [-l <log-file>] -r <run-command> [-t <target>] " <<
      "<source>...\n" <<
      "       #{program} -h\n" <<
      "options:\n" <<
      "       -h, --help:    prints this help text\n" <<
      "       -l, --logfile: detailed logging to file\n" <<
      "       -r, --run:     sets the command that builds and runs the " <<
      "test suite\n" <<
      "       -t, --target:  sets the target file built from the source " <<
      "files\n" <<
      "                      (must be set for C++ and Java)" <<
      "\n"
    exit 1
  end

  source_files = []

  while ARGV.any?
    case ARGV.shift
    when '-r', '--run'     then run_cmd       = ARGV.shift
    when '-t', '--target'  then target        = ARGV.shift
    when '-l', '--logfile' then log_file_name = ARGV.shift
    when '-h', '--help'    then usage
    when /^-.*/ then $stderr.puts "Unknown arg: #{$MATCH}"; usage
    when /.*/   then source_files << $MATCH
    end
  end

  $log_file = File.new log_file_name, 'w' if log_file_name

  usage if source_files.empty? or run_cmd.nil?

  FileMutator.test_suite = TestSuite.new run_cmd
  source_files.each { |file_name| FileUtils.touch file_name }
  FileMutator.test_suite.check 'before mutations'

  mutators = source_files.map { |file_name|
    case file_name
    when /\.py$/
      if target
        $stderr.puts "Don't set --target (-t) for python files. Targets " +
          "will be set implicitly to the corresponding .pyc files."
        exit 1
      end
      target = file_name + 'c'
    when /\.(cc|hh|cpp|hpp|C|java)$/
      unless target
        $stderr.puts "No target file set."
        exit 1
      end
    end
    FileMutator.new file_name, target
  }

  grand_total = mutators.inject(0) { |sum, fm| sum + fm.nr_of_mutations }

  FileMutator.progress = Progress.new grand_total, Time.now
  mutators.each { |fm| FileMutator.process fm }

  FileMutator.print_statistics
  FileMutator.test_suite.check 'after mutations'

  $log_file.close if $log_file
end
