// Simulate a full contribution

const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const SGT = artifacts.require("SGT");
const SNT = artifacts.require("SNT");
const MultisigWallet = artifacts.require("MultisigWallet");
const ContributionWallet = artifacts.require("ContributionWallet");
const StatusContributionMock = artifacts.require("StatusContributionMock");
const DevTokensHolder = artifacts.require("DevTokensHolderMock");
const SGTExchanger = artifacts.require("SGTExchanger");
const DynamicCeiling = artifacts.require("DynamicCeiling");
const SNTPlaceHolderMock = artifacts.require("SNTPlaceHolderMock");
const ExternalToken = artifacts.require("ExternalToken");

const setHiddenPoints = require("./helpers/hiddenPoints.js").setHiddenPoints;
const assertFail = require("./helpers/assertFail");

contract("StatusContribution", (accounts) => {
    let multisigStatus;
    let multisigComunity;
    let multisigSecondarySell;
    let multisigDevs;
    let miniMeFactory;
    let sgt;
    let snt;
    let statusContribution;
    let contributionWallet;
    let devTokensHolder;
    let sgtExchanger;
    let dynamicCeiling;
    let sntPlaceHolder;
    let externalToken;

    const points = [ [ 1000000, web3.toWei(3) ],
                     [ 1001000, web3.toWei(13) ],
                     [ 1002000, web3.toWei(15) ] ];
    const startBlock = 1000000;
    const stopBlock = 1003000;
    const sgtPreferenceBlocks = 2000;
    const sgtLimit = web3.toWei(0.1);

    it("Should deploy Contribution contracts", async () => {
        multisigStatus = await MultisigWallet.new([ accounts[ 0 ] ], 1);
        multisigComunity = await MultisigWallet.new([ accounts[ 1 ] ], 1);
        multisigSecondarySell = await MultisigWallet.new([ accounts[ 2 ] ], 1);
        multisigDevs = await MultisigWallet.new([ accounts[ 3 ] ], 1);
        miniMeFactory = await MiniMeTokenFactory.new();
        sgt = await SGT.new(miniMeFactory.address);
        await sgt.generateTokens(accounts[ 4 ], 5000);

        snt = await SNT.new(miniMeFactory.address);
        statusContribution = await StatusContributionMock.new();
        contributionWallet = await ContributionWallet.new(
            multisigStatus.address,
            stopBlock,
            statusContribution.address);
        devTokensHolder = await DevTokensHolder.new(
            multisigDevs.address,
            statusContribution.address,
            snt.address);
        sgtExchanger = await SGTExchanger.new(sgt.address, snt.address);
        dynamicCeiling = await DynamicCeiling.new();

        await setHiddenPoints(dynamicCeiling, points);

        sntPlaceHolder = await SNTPlaceHolderMock.new(
            multisigComunity.address,
            snt.address,
            statusContribution.address,
            sgtExchanger.address);

        await snt.changeController(statusContribution.address);
        await sgt.changeController(sgtExchanger.address);

        await statusContribution.initialize(
          snt.address,
          startBlock,
          stopBlock,
          sgtPreferenceBlocks,
          sgtLimit,
          dynamicCeiling.address,

          contributionWallet.address,

          devTokensHolder.address,

          multisigSecondarySell.address,
          sgt.address,

          sgtExchanger.address,
          5000 * 2,

          sntPlaceHolder.address);

        externalToken = await ExternalToken.new();
        await externalToken.generateTokens(accounts[ 0 ], 1000);
    });

    it("Should send and recover tokens to the StatusContribution", async () => {
        await externalToken.transfer(statusContribution.address, 100);

        const balanceBefore = await externalToken.balanceOf(accounts[ 0 ]);

        assert.equal(balanceBefore.toNumber(), 900);

        await statusContribution.claimTokens(externalToken.address);

        const afterBefore = await externalToken.balanceOf(accounts[ 0 ]);

        assert.equal(afterBefore.toNumber(), 1000);
    });

    it("Should recover tokens sent to SNT", async () => {
        await externalToken.transfer(snt.address, 100);

        const balanceBefore = await externalToken.balanceOf(accounts[ 0 ]);

        assert.equal(balanceBefore.toNumber(), 900);

        await statusContribution.claimTokens(externalToken.address);

        const afterBefore = await externalToken.balanceOf(accounts[ 0 ]);

        assert.equal(afterBefore.toNumber(), 1000);
    });
});
