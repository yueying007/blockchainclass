var SimpleArbi = artifacts.require("../contracts/SimpleArbi.sol");

module.exports = function(deployer, network, accounts) {
 deployer.deploy(SimpleArbi);
};
