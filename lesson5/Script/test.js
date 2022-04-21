WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
Curvepool = '0xD51a44d3FaE010294C616388b506AcdA1bfAAE46';
Uniswappool = '0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36';

instance = await SimpleArbi.deployed();
instance.send(web3.utils.toWei('10', 'ether'));
instance.ETHtoWETH(web3.utils.toWei('5', 'ether'));

weth = await instance.getTokenBalance(WETH, instance.address);
weth.toString();

instance.setLock(false);
instance.flashLoan(WETH, web3.utils.toWei('100'))

instance.SwapBase(Curvepool, 2, web3.utils.toWei('1'), 2, 0, WETH, USDT);
usdt = await instance.getTokenBalance(USDT, instance.address);
usdt.toString();

instance.SwapBase(Curvepool, 2, usdt, 0, 2, USDT, WETH);
weth = await instance.getTokenBalance(WETH, instance.address);
weth.toString();

instance.SwapBase(Uniswappool, 1, web3.utils.toWei('1'), 0, 0, WETH, USDT);
usdt = await instance.getTokenBalance(USDT, instance.address);
usdt.toString();

instance.SwapBase(Uniswappool, 1, usdt, 0, 0, USDT, WETH);
weth = await instance.getTokenBalance(WETH, instance.address);
weth.toString();