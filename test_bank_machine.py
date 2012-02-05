import bank_machine
import unittest

class TestBankMachine(unittest.TestCase):
    def test_1(self):
        m = bank_machine.BankMachine()

        m.fillCash(1000000)
        self.assertEqual(1000000, m.cash)
     
        jonas = "19670223-2973"
     
        m.addUser(jonas, 1234)
        self.assertEqual(1, m.nrOfUsers())
     
        m.deposit(jonas, 2000)
        result = m.withdraw(500, jonas, 1234)
        self.assertEqual('OK', result)
     
        result = m.deposit('xyz', 2000)
        self.assertEqual('UNKNOWN_USER', result)
     
        result = m.withdraw(5000000, jonas, 1234)
        self.assertEqual('NOT_ENOUGH_MONEY_IN_ACCOUNT', result)
     
        result = m.withdraw(5000000, 'xyz', 1234)
        self.assertEqual('UNKNOWN_USER', result)
     
        result = m.withdraw(100, jonas, 7777)
        self.assertEqual('WRONG_PIN_CODE', result)
     
        m.deposit(jonas, 20000000)
        result = m.withdraw(20000000, jonas, 1234)
        self.assertEqual('NOT_ENOUGH_MONEY_IN_MACHINE', result)
        self.assertEqual(20001500, m.balance(jonas))
     
        result = m.balance('xyz')
        self.assertEqual('UNKNOWN_USER', result)

if __name__ == '__main__':
    unittest.main()
