#include "TestBankMachine.hh"
#include "BankMachine.hh"

// Registers the fixture into the 'registry'
CPPUNIT_TEST_SUITE_REGISTRATION(TestBankMachine);

void TestBankMachine::test1()
{
  BankMachine m;

  m.fillCash(1000000);
  CPPUNIT_ASSERT_EQUAL(1000000, m.cash());

  const char* jonas = "19670223-2973";

  m.addUser(jonas, 1234);
  CPPUNIT_ASSERT_EQUAL(1, m.nrOfUsers());
  CPPUNIT_ASSERT_EQUAL(0, m.balance(jonas));

  BankMachine::Result result = m.deposit("xyz", 2000);
  CPPUNIT_ASSERT_EQUAL(BankMachine::UNKNOWN_USER, result);

  result = m.deposit(jonas, 2000);
  CPPUNIT_ASSERT_EQUAL(BankMachine::OK, result);
  CPPUNIT_ASSERT_EQUAL(2000, m.balance(jonas));

  m.withdraw(500, jonas, 1234); // Normal

  result = m.withdraw(500, "abc", 1234);
  CPPUNIT_ASSERT_EQUAL(BankMachine::UNKNOWN_USER, result);
  CPPUNIT_ASSERT_EQUAL(1500, m.balance(jonas));

  m.withdraw(100, jonas, 7777); // Wrong PIN

  result = m.withdraw(5000000, jonas, 1234);
  CPPUNIT_ASSERT_EQUAL(BankMachine::NOT_ENOUGH_MONEY_IN_ACCOUNT, result);

  m.deposit(jonas,    20000000);
  result = m.withdraw(20000000, jonas, 1234);
}
