class UserData:
    def __init__(self, money, pin):
        self.money = money
        self.pin = pin

class BankMachine:
    def __init__(self):
        self.cash = 0
        self.users = {}

    def fillCash(self, amount):
        self.cash += amount

    def addUser(self, id, pin):
        self.users[id] = UserData(0, pin)

    def deposit(self, user_id, amount):
        if user_id not in self.users: return 'UNKNOWN_USER'
        self.users[user_id].money += amount

    def withdraw(self, amount, user_id, pin):
        if user_id not in self.users:      return 'UNKNOWN_USER'
        if pin != self.users[user_id].pin: return 'WRONG_PIN_CODE'              
        if self.balance(user_id) < amount: return 'NOT_ENOUGH_MONEY_IN_ACCOUNT'
        if self.cash < amount:             return 'NOT_ENOUGH_MONEY_IN_MACHINE'

        self.deposit(user_id, -amount)
        return 'OK'

    def balance(self, user_id):
        if user_id not in self.users: return 'UNKNOWN_USER'
        return self.users[user_id].money

    def nrOfUsers(self):
        return len(self.users)
