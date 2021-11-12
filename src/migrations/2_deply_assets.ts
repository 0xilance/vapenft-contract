const PlatformAsset = artifacts.require("PlatformAsset");

module.exports = function (deployer) {
    deployer.deploy(PlatformAsset, "https://cent.io/assets");
} as Truffle.Migration;
