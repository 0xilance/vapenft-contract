const Apes2981 = artifacts.require("Apes2981");

module.exports = function (deployer) {
    deployer.deploy(Apes2981, "Vapenapes", 'VAPES', 10000, '98065456578');
} as Truffle.Migration;