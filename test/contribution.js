// Simulate a full contribution

const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const SGT = artifacts.require("SGT");
const SNT = artifacts.require("SNT");
const MultisigWallet = artifacts.require("MultisigWallet");
const ContributionWallet = artifacts.require("ContributionWallet");
const StatusContribution = artifacts.require("StatusContribution");
const DevTokensHolder = artifacts.require("DevTokensHolder");
const SGTExchanger = artifacts.require("SGTExchanger");
const DynamicHiddenCap = artifacts.require("DynamicHiddenCap");
const SNTPlaceHolder = artifacts.require("SNTPlaceHolder");

const setHiddenPoints = require("./helpers/hiddenPoints.js").setHiddenPoints;

contract("StatusContribution", (accounts) => {
    let multisigStatus;
    let multisigComunity;
    let multisigSecundarySell;
    let miniMeFactory;
    let sgt;
    let snt;
    let statusContribution;
    let contributionWallet;
    let devTokensHolder;
    let sgtExchanger;
    let dynamicHiddenCap;
    let sntPlaceHolder;

    const points = [ [ 1000000, web3.toWei(1000) ],
        [ 1001000, web3.toWei(21000) ],
        [ 1002000, web3.toWei(61000) ] ];
    const startBlock = 1000000;
    const stopBlock = 1003000;

    beforeEach(async () => {
        multisigStatus = await MultisigWallet.new([ accounts[ 0 ] ], 1);
        multisigComunity = await MultisigWallet.new([ accounts[ 1 ] ], 1);
        multisigSecundarySell = await MultisigWallet.new([ accounts[ 2 ] ], 1);
        miniMeFactory = await MiniMeTokenFactory.new();
        sgt = await SGT.new(miniMeFactory.address);
        snt = await SNT.new(miniMeFactory.address);
        statusContribution = await StatusContribution.new();
        contributionWallet = await ContributionWallet.new(
            multisigStatus.address,
            stopBlock,
            statusContribution.address);
        devTokensHolder = await DevTokensHolder.new(
            statusContribution.address,
            snt.address);
        sgtExchanger = await SGTExchanger.new(sgt.address, snt.address);
        dynamicHiddenCap = await DynamicHiddenCap.new();

        await setHiddenPoints(dynamicHiddenCap, points);

        sntPlaceHolder = await SNTPlaceHolder.new(
            multisigComunity.adress,
            snt.address,
            statusContribution.address);

        await snt.changeController(statusContribution.address);

        await statusContribution.initialize(
          snt.address,
          startBlock,
          stopBlock,
          dynamicHiddenCap.address,

          contributionWallet.address,

          devTokensHolder.address,

          multisigSecundarySell.address,
          sgtExchanger.address,

          sntPlaceHolder.address);
        await sgt.generateTokens(accounts[ 0 ], web3.toWei(25000000));
        await sgt.changeController(sgtExchanger.address);
    });

    it("Check initial parameters", async () => {
        assert.equal(await snt.controller(), statusContribution.address);
        assert.equal(await sgt.controller(), sgtExchanger.address);
    });
});
