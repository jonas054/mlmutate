import java.util.HashMap;

public class BankMachine
{
    enum Result {
            OK,
            UNKNOWN_USER,
            WRONG_PIN_CODE,
            NOT_ENOUGH_MONEY_IN_MACHINE,
            NOT_ENOUGH_MONEY_IN_ACCOUNT }

    public BankMachine()
    {
        itsUsers = new HashMap<String, UserData>();
    }

    public int cash() { return itsCash; }

    public void fillCash(int amount) { itsCash += amount; }

    public void addUser(String id, int pin)
    {
        UserData ud = new UserData(pin);
        itsUsers.put(id, ud);
    }

    public Result deposit(String userId, int amount)
    {
        if (!isUser(userId))
            return Result.UNKNOWN_USER;

        itsUsers.get(userId).money += amount;
        return Result.OK;
    }

    public Result withdraw(int amount, String userId, int pin)
    {
        if (!isUser(userId))
            return Result.UNKNOWN_USER;

        if (pin != itsUsers.get(userId).pin)
            return Result.WRONG_PIN_CODE;

        if (balance(userId) < amount)
            return Result.NOT_ENOUGH_MONEY_IN_ACCOUNT;

        if (itsCash < amount)
            return Result.NOT_ENOUGH_MONEY_IN_MACHINE;

        deposit(userId, -amount);
        return Result.OK;
    }

    public int balance(String userId)
    {
        assert(isUser(userId));
        return itsUsers.get(userId).money;
    }

    public int nrOfUsers() { return itsUsers.size(); }

    private boolean isUser(String userId)
    {
        return itsUsers.containsKey(userId);
    }

    private class UserData
    {
        UserData(int aPin) { pin = aPin; }
        int pin;
        int money;
    }

    private int                       itsCash;
    private HashMap<String, UserData> itsUsers;
}
