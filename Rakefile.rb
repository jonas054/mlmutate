require 'rake/clean'

$, = ' '

def dependencies(cc_file)
  files = `g++ -E #{cc_file}`.scan(%r'^# \d+ "([^<].*)"').flatten
  files.reject { |x| x =~ %r"^/usr/(include|lib/gcc)/" }.uniq
end

task :default => 'TestMain' do
  sh "./TestMain"
end

FileList['*.cc'].each { |cc_file|
  file cc_file.ext('o') => dependencies(cc_file) do |t|
    sh "g++ -o #{t.name} -c #{cc_file}"
  end
}

file 'TestMain' => ['TestMain.o', 'TestBankMachine.o', 'BankMachine.o'] do |t|
  sh "g++ -o #{t.name} #{t.prerequisites} -lcppunit"
end

CLEAN.include '*.o'

# --- Java ---

ENV['CLASSPATH'] =
    ['.',
     '/home/jonas/eclipse3.4.2-for-plugin-dev/plugins/org.junit_3.8.2.v20080602-1318/junit.jar',
     '/home/xtsjarv/.rvm/src/jruby-1.3.1-p1.4.0/build_lib/junit.jar'].join(':')

task :javatest => :javabuild do
  sh "java junit.textui.TestRunner TestBankMachine"
end

task :javabuild => %w'BankMachine.class TestBankMachine.class'

rule '.class' => '.java' do |t|
  sh "javac #{t.prerequisites}"
end

CLEAN.include '*.class'

task :cppmutate do
  sh './mutate -r rake -t TestMain BankMachine.cc'
end

task :javamutate do
  sh './mutate -r "rake javatest" -t BankMachine.class BankMachine.java'
end

task :rubymutate do
  sh './mutate -r "ruby test_bank_machine.rb" bank_machine.rb'
end

task :pymutate do
  sh './mutate -r "python test_bank_machine.py" bank_machine.py'
end

task :mutate => [:rubymutate, :pymutate, :cppmutate, :javamutate]

CLEAN.include '*.pyc'
