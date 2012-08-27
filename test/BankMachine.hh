#ifndef BANK_MACHINE_HH
#define BANK_MACHINE_HH

#include <string>
#include <map>

class BankMachine
{
public:
  enum Result { OK,
                UNKNOWN_USER,
                WRONG_PIN_CODE,
                NOT_ENOUGH_MONEY_IN_MACHINE,
                NOT_ENOUGH_MONEY_IN_ACCOUNT };

  BankMachine(): itsCash(0) {}

  int cash() const { return itsCash; }

  void fillCash(int amount) { itsCash += amount; }

  void addUser(const std::string& id, int pin);

  int nrOfUsers() const { return itsUsers.size(); }

  Result deposit(const std::string& userId, int amount);

  Result withdraw(int amount, const std::string& userId, int pin);

  int balance(const std::string& userId) const;

  bool isUser(const std::string& userId) const;

private:
  struct UserData
  {
    int pin;
    int money;
  };

  int                             itsCash;
  std::map<std::string, UserData> itsUsers;
};

#endif // BANK_MACHINE_HH
