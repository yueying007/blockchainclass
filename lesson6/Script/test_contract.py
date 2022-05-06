from web3 import Web3
from eth_abi import encode_abi
import json

PROVIDER = 'http://127.0.0.1:8545'
FORMAT = ['uint', 'uint256', 'uint256', 'address', 'address', 'address']
WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7'
Curvepool = '0xD51a44d3FaE010294C616388b506AcdA1bfAAE46'
Uniswappool = '0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36'


def to_wei(quantity, decimal):
    """
    quantity转换为amount
    :param quantity: float
    :param decimal: int
    """
    return int(quantity*(10**decimal))


def test_contract(contract_address, account, private_key):

    abi_location = '../Contract/SimpleArbi.json'
    with open(abi_location) as file:
        abi_dict = json.load(file)
    contract_abi = abi_dict.get('abi')
    w3 = Web3(Web3.HTTPProvider(PROVIDER))
    contract = w3.eth.contract(address=contract_address, abi=contract_abi)

    data1 = encode_abi(FORMAT, [2, 2, 0, WETH, USDT, Curvepool])
    data2 = encode_abi(FORMAT, [1, 0, 0, USDT, WETH, Uniswappool])
    tx = contract.functions.execute([data1, data2], to_wei(1, 18))

    # 发送交易
    nonce = w3.eth.getTransactionCount(account)
    tx_dict = tx.buildTransaction({'gas': 1000000,
                                   'gasPrice': to_wei(20, 9),
                                   'nonce': nonce})
    signed_tx = w3.eth.account.signTransaction(tx_dict, private_key=private_key)
    tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
    tx_hash = tx_hash.hex()
    print('transaction发送成功:', tx_hash)


if __name__ == '__main__':
    test_contract(contract_address='',
                  account='',
                  private_key='')
