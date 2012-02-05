class BankMachine
  UserData = Struct.new :money, :pin

  def initialize
    @cash = 0
    @users = {}
  end

  attr_reader :cash
  
  def fillCash(amount)
    @cash += amount
  end

  def addUser(id, pin)
    @users[id] = UserData.new 0, pin
  end

  def deposit(userId, amount)
    return :UNKNOWN_USER unless @users.has_key? userId
    @users[userId].money += amount
  end

  def withdraw(amount, userId, pin)
    return :UNKNOWN_USER unless @users.has_key? userId
    return :WRONG_PIN_CODE              if pin != @users[userId].pin
    return :NOT_ENOUGH_MONEY_IN_ACCOUNT if balance(userId) < amount
    return :NOT_ENOUGH_MONEY_IN_MACHINE if @cash < amount

    deposit userId, -amount
    :OK
  end

  def balance(userId)
    return :UNKNOWN_USER unless @users.has_key? userId
    @users[userId].money
  end

  def nrOfUsers() @users.size end
end
