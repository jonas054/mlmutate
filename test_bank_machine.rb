require 'test/unit'
load 'bank_machine.rb'

class TestBackMachine < Test::Unit::TestCase
  def test_1
    m = BankMachine.new

    m.fillCash 1000000
    assert_equal 1000000, m.cash

    jonas = "19670223-2973"

    m.addUser jonas, 1234
    assert_equal 1, m.nrOfUsers

    m.deposit jonas, 2000
    result = m.withdraw 500, jonas, 1234
    assert_equal :OK, result

    result = m.deposit 'xyz', 2000
    assert_equal :UNKNOWN_USER, result
    
    result = m.withdraw 5000000, jonas, 1234
    assert_equal :NOT_ENOUGH_MONEY_IN_ACCOUNT, result

    result = m.withdraw 5000000, 'xyz', 1234
    assert_equal :UNKNOWN_USER, result
    
    result = m.withdraw 100, jonas, 7777
    assert_equal :WRONG_PIN_CODE, result

    m.deposit jonas, 20000000
    result = m.withdraw 20000000, jonas, 1234
    assert_equal :NOT_ENOUGH_MONEY_IN_MACHINE, result
    assert_equal 20001500, m.balance(jonas)

    result = m.balance 'xyz'
    assert_equal :UNKNOWN_USER, result
end
end
