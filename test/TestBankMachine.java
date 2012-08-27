import junit.framework.*;

public class TestBankMachine extends TestCase
{
    public void test1()
    {
        BankMachine m = new BankMachine();

        m.fillCash(1000000);
        assertEquals(1000000, m.cash());

        String jonas = "19670223-2973";

        m.addUser(jonas, 1234);
        assertEquals(1, m.nrOfUsers());

        BankMachine.Result result = m.deposit(jonas, 2000);
        assertEquals(BankMachine.Result.OK, result);

        result = m.withdraw(500, jonas, 1234); // Normal
        assertEquals(BankMachine.Result.OK, result);

        result = m.deposit("xyz", 2000);
        assertEquals(BankMachine.Result.UNKNOWN_USER, result);

        result = m.withdraw(5000000, jonas, 1234);
        assertEquals(BankMachine.Result.NOT_ENOUGH_MONEY_IN_ACCOUNT, result);

        result = m.withdraw(100, jonas, 7777);
        assertEquals(BankMachine.Result.WRONG_PIN_CODE, result);

        result = m.withdraw(100, "xyz", 7777);
        assertEquals(BankMachine.Result.UNKNOWN_USER, result);

        m.deposit(jonas, 20000000);
        result = m.withdraw(20000000, jonas, 1234);
        assertEquals(BankMachine.Result.NOT_ENOUGH_MONEY_IN_MACHINE, result);
        assertEquals(20001500, m.balance(jonas));
    }
}
