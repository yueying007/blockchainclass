WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';

instance = await SimpleArbi.deployed();

owner = await instance.getOwner()
owner

instance.send(web3.utils.toWei('10', 'ether'))
instance.ETHtoWETH(web3.utils.toWei('5', 'ether'))

weth = await instance.getTokenBalance(WETH, instance.address);
weth.toString();

instance.turnOutToken(WETH, weth)
weth = await instance.getTokenBalance(WETH, accounts[0]);
weth.toString();

instance.flashLoan(WETH, web3.utils.toWei('1'))
