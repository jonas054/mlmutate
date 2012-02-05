CXX = g++
DEP_FILES = $(patsubst %.cc,.%.d,$(wildcard *.cc))

all: TestMain
	./TestMain

-include $(DEP_FILES)

.%.d: %.cc
	@echo $*.o .$*.d : "\\" >$@
	@$(CXX) -E $< | \
	 awk -F'"' '/^# [0-9]+ "/ {print $$2 " \\"}' | sed 's-\\\\-/-g' | \
	 grep -v '^<' | sort -u >>$@
	@-chmod a=rw $@ 1> /dev/null 2>&1

%.o: %.cc
	g++ -o $@ -c $<

TestMain: TestMain.o TestBankMachine.o BankMachine.o
	g++ -o $@ $^ -lcppunit

clean:
	-rm *.o .*.d
