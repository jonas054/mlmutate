#ifndef TEST_MY_CLASS_HH
#define TEST_MY_CLASS_HH

#include <cppunit/extensions/HelperMacros.h>

class TestBankMachine : public CppUnit::TestFixture
{
    CPPUNIT_TEST_SUITE(TestBankMachine);
    CPPUNIT_TEST(test1);
    CPPUNIT_TEST_SUITE_END();

public:
    void test1();
};

#endif // TEST_MY_CLASS_HH
