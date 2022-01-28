const VapenApes2981 = artifacts.require("VapenApes2981");

module.exports = function (deployer) {
  deployer.deploy(VapenApes2981, "Vapenapes", "VAPES", 10000, "98065456578");
} as Truffle.Migration;
