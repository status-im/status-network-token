const randomBytes = require("random-bytes");

const MultiSigWallet = artifacts.require("MultiSigWallet");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const SGT = artifacts.require("SGT");
const SNT = artifacts.require("SNT");
const StatusContribution= artifacts.require("StatusContribution");
const ContributionWallet = artifacts.require("ContributionWallet");
const DevTokensHolder = artifacts.require("DevTokensHolder");
const SGTExchanger = artifacts.require("SGTExchanger");
const DynamicCeiling = artifacts.require("DynamicCeiling");
const SNTPlaceHolder = artifacts.require("SNTPlaceHolder");


// Set hidden curves
const setHiddenCurves = async function(dynamicCeiling, curves, nHiddenCurves) {
    let hashes = [];
    let i = 0;
    for (let c of curves) {
        let salt = await randomBytes(32);
        console.log(`Curve ${i} has salt: ${salt.toString("hex")}`);
        let h = await dynamicCeiling.calculateHash(c[0], c[1], c[2], i === curves.length - 1, salt);
        hashes.push(h);
        i += 1;
    }
    for (; i < nHiddenCurves; i += 1) {
        let salt = randomBytes(32);
        hashes.push(web3.sha3(salt));
    }
    await dynamicCeiling.setHiddenCurves(hashes);
    console.log(`${i} curves set!`);
};


// All of these constants need to be configured before deploy
const addressOwner = "0xf93df8c288b9020e76583a6997362e89e0599e99";
const addressesStatus = [
    "0x2ca9d4d0fd9622b08de76c1d484e69a6311db765",
];
const multisigStatusReqs = 1
const addressesCommunity = [
    "0x166ddbcfe4d5849b0c62063747966a13706a4af7",
];
const multisigCommunityReqs = 1
const addressesReserve = [
    "0x4781fee94e7257ffb6e3a3dcc5f8571ddcc02109",
];
const multisigReserveReqs = 1
const addressesDevs = [
    "0xcee9f54a23324867d8537589ba8dc6c8a6e9d0b9",
];
const multisigDevsReqs = 1
const addressSGT = "";

const startBlock = 3800000;
const endBlock = 3900000;

const maxSGTSupply = 500000000;

const curves = [
    [web3.toWei(1000), 30, 10**12],
    [web3.toWei(21000), 30, 10**12],
    [web3.toWei(61000), 30, 10**12],
];
const nHiddenCurves = 7;


module.exports = async function(deployer, network, accounts) {
    if (network === "development") return;  // Don't deploy on tests

    // Multisig wallets
    let multisigStatus = await MultiSigWallet.new(addressesStatus, multisigStatusReqs);
    console.log("\nMultiSigWallet Status: " + multisigStatus.address);
    let multisigCommunity = await MultiSigWallet.new(addressesCommunity, multisigCommunityReqs);
    console.log("MultiSigWallet Community: " + multisigCommunity.address);
    let multisigReserve = await MultiSigWallet.new(addressesReserve, multisigReserveReqs);
    console.log("MultiSigWallet Reserve: " + multisigReserve.address);
    let multisigDevs = await MultiSigWallet.new(addressesDevs, multisigDevsReqs);
    console.log("MultiSigWallet Devs: " + multisigDevs.address);

    // MiniMe
    console.log();
    let miniMeTokenFactory = await MiniMeTokenFactory.new();
    console.log("MiniMeTokenFactory: " + miniMeTokenFactory.address);

    // SGT
    let sgt;
    if (addressSGT.length === 0) {  // Testnet
        sgt = await SGT.new(miniMeTokenFactory.address);
    } else {
        sgt = await SGT.at(addressSGT);
    }
    console.log("SGT: " + sgt.address);

    // SNT
    let snt = await SNT.new(miniMeTokenFactory.address);
    console.log("SNT: " + snt.address);

    // StatusContribution
    let statusContribution = await StatusContribution.new();
    console.log("StatusContribution: " + statusContribution.address);

    // ContributionWallet
    let contributionWallet = await ContributionWallet.new(
        multisigStatus.address,
        endBlock,
        statusContribution.address);
    console.log("ContributionWallet: " + contributionWallet.address);

    // DevTokensHolder
    let devTokensHolder = await DevTokensHolder.new(
        multisigDevs.address,
        statusContribution.address,
        snt.address);
    console.log("DevTokensHolder: " + devTokensHolder.address);

    // SGTExchanger
    let sgtExchanger = await SGTExchanger.new(sgt.address, snt.address, statusContribution.address);
    console.log("SGTExchanger: " + sgtExchanger.address);

    // DynamicCeiling
    let dynamicCeiling = await DynamicCeiling.new(addressOwner, statusContribution.address);
    console.log("DynamicCeiling: " + dynamicCeiling.address);

    // SNTPlaceHolder
    let sntPlaceHolder = await SNTPlaceHolder.new(
        multisigCommunity.address,
        snt.address,
        statusContribution.address,
        sgtExchanger.address);
    console.log("SNTPlaceHolder: " + sntPlaceHolder.address);

    // Change controllers
    console.log();
    await snt.changeController(statusContribution.address);
    console.log("SNT changed controller!");

    // Initialize StatusContribution
    console.log();
    await statusContribution.initialize(
        snt.address,
        sntPlaceHolder.address,

        startBlock,
        endBlock,

        dynamicCeiling.address,

        contributionWallet.address,

        multisigReserve.address,
        sgtExchanger.address,
        devTokensHolder.address,

        sgt.address,
        maxSGTSupply);
    console.log("StatusContribution initialized!");

    // Set hidden curves
    console.log();
    await setHiddenCurves(dynamicCeiling, curves, nHiddenCurves);
    console.log("DynamicCeiling hidden curves set!");
};
