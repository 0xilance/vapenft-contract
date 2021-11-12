const PoolToken = artifacts.require("PlatformPool");

module.exports = function (deployer) {
    deployer.deploy(PoolToken, "https://cent.io/pools");
} as Truffle.Migration;
