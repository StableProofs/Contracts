# (c) 2020 Brandon McFarland

# @title CoinbaseOracle
# @author Brandon McFarland
# @notice A contract for writing Coinbase Oracle data to chain and reading it

PriceUpdated: event({
    price: uint256
})

admin: public(address)
lastUpdate: public(timestamp)
message: public(string[514])
signature: public(string[256])
price: public(uint256)

@public
def __init__(_admin: address):
    self.admin = _admin

@public
def setPrice(_timestamp: timestamp, _message: string[514], _signature: string[256], _price: uint256):
    if not msg.sender == self.admin:
        raise "Error running setPrice - Only the contract admin can update the price"
    self.lastUpdate = _timestamp
    self.message = _message
    self.signature = _signature
    self.price = _price

@public
def changeAdmin(_new_admin: address):
    if not msg.sender == self.admin:
        raise "Error running setPrice - Only the contract admin can update the admin address"
    self.admin = _new_admin

@public
@payable
def __default__():
    pass
