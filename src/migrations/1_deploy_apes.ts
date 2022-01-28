const VapenApes2981 = artifacts.require("VapenApes");

module.exports = function (deployer) {
  deployer.deploy(VapenApes2981);
} as Truffle.Migration;
