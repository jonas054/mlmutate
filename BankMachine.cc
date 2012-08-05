#include "BankMachine.hh"
#include <cassert>

using std::string;

void BankMachine::addUser(const string& id, int pin) {
  UserData ud;
  ud.money = 0;
  ud.pin = pin;
  itsUsers[id] = ud;
}

BankMachine::Result BankMachine::deposit(const string& userId, int amount) {
  if (!isUser(userId))
    return UNKNOWN_USER;

  itsUsers[userId].money += amount;
  return OK;
}

BankMachine::Result BankMachine::withdraw(int           amount,
                                          const string& userId,
                                          int           pin) {
  if (!isUser(userId))
    return UNKNOWN_USER;

  if (pin != itsUsers[userId].pin)
    return WRONG_PIN_CODE;

  if (balance(userId) < amount)
    return NOT_ENOUGH_MONEY_IN_ACCOUNT;

  if (itsCash < amount)
    return NOT_ENOUGH_MONEY_IN_MACHINE;

  deposit(userId, -amount);
  return OK;
}

int BankMachine::balance(const string& userId) const {
  assert(isUser(userId));
  return itsUsers.find(userId)->second.money;
}

bool BankMachine::isUser(const string& userId) const {
  return itsUsers.find(userId) != itsUsers.end();
}
