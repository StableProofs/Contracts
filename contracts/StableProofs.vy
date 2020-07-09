# (c) 2020 Brandon McFarland

# @title StableProofs
# @author Brandon McFarland
# @notice A proof of burn stablecoin

from vyper.interfaces import ERC20

contract ORACLE:
    def price() -> uint256: modifying

implements: ERC20

Transfer: event({
    sender: indexed(address)
    , receiver: indexed(address)
    , value: uint256
})

Approval: event({ 
    owner: indexed(address)
    , spender: indexed(address)
    , value: uint256
})

Mint: event({
    minter: indexed(address)
    , receiver: indexed(address)
    , value: uint256
    , mint: uint256
})

ContractPaused: event({
    isPaused: bool
})

name: public(string[12])
symbol: public(string[3])
decimals: public(uint256)
balanceOf: public(map(address, uint256))
allowances: map(address, map(address, uint256))
total_supply: uint256
minter: public(address)
oracle: public(address)
price: public(uint256)
admin: public(address)
adminFee: public(uint256)
isPaused: public(bool)
PRECISION: constant(uint256) = 10**18

@public
def __init__(_name: string[12], _symbol: string[3], _decimals: uint256, _supply: uint256, _oracle: address, _admin: address, _admin_fee: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.minter = msg.sender
    self.oracle = _oracle   
    self.admin = _admin
    self.adminFee = _admin_fee
    log.Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@public
@constant
def totalSupply() -> uint256:
    return self.total_supply

@public
@constant
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]

@public
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log.Transfer(msg.sender, _to, _value)
    return True

@public
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowances[_from][msg.sender] -= _value
    log.Transfer(_from, _to, _value)
    return True

@public
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log.Approval(msg.sender, _spender, _value)
    return True

@public
def updateAdminFee(_amount: uint256):
    if not msg.sender == self.admin:
        raise "Error running updateAdminFee - Only the contract admin can update the admin fee"
    self.adminFee = _amount

@public
def updateAdminAddress(_admin: address):
    if not msg.sender == self.admin:
        raise "Error running updateAdminaddress - Only the contract admin can update the admin address"
    self.admin = _admin

@public
def pauseContract():
    if not msg.sender == self.admin:
        raise "Error running pauseContract - Only the contract admin can pause this contract"
    self.isPaused = True
    log.ContractPaused(self.isPaused)

@public
def unpauseContract():
    if not msg.sender == self.admin:
        raise "Error running pauseContract - Only the contract admin can unpause this contract"
    self.isPaused = False
    log.ContractPaused(self.isPaused)

@public
@payable
def mint(_to: address):
    if not msg.value > 0:
        raise "Error running mint - msg.value must be greater than 0"
    if not self.isPaused == False:
        raise "Error running mint - The contract is paused"

    self.price = ORACLE(self.oracle).price()
    price_decimals: uint256 = convert( (((convert(self.price,decimal)/convert(100,decimal)) - convert(self.price/100, decimal)) * convert(100,decimal)), uint256)
    price_integer: uint256 = self.price/100
    fee: uint256 = convert( convert( ((self.adminFee * as_unitless_number(msg.value) ) / (100 * (PRECISION))), decimal ), uint256 )
    value_after_fee: uint256 = as_unitless_number(msg.value) - fee
    mint_left: uint256 = as_unitless_number(value_after_fee)*price_integer
    mint_right: uint256 = (as_unitless_number(value_after_fee)/100)*price_decimals
    mint_value: uint256 = mint_left + mint_right
    self.total_supply += mint_value
    self.balanceOf[_to] += mint_value

    log.Mint(msg.sender, _to, as_unitless_number(value_after_fee), mint_value)
    send(ZERO_ADDRESS, value_after_fee)

@public
def withdrawFees(_amount: uint256, _to: address):
    if not msg.sender == self.admin:
        raise "Error running withdrawFees - Only the contract admin can withdraw fees"

    send(_to, _amount)


@public
@payable
def __default__():
    pass
