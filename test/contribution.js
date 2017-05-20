// Simulate a full contribution

const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const SGT = artifacts.require("SGT");
const SNT = artifacts.require("SNT");
const MultisigWallet = artifacts.require("MultisigWallet");
const ContributionWallet = artifacts.require("ContributionWallet");
const StatusContributionMock = artifacts.require("StatusContributionMock");
const DevTokensHolder = artifacts.require("DevTokensHolder");
const SGTExchanger = artifacts.require("SGTExchanger");
const DynamicCeiling = artifacts.require("DynamicCeiling");
const SNTPlaceHolder = artifacts.require("SNTPlaceHolder");

const setHiddenPoints = require("./helpers/hiddenPoints.js").setHiddenPoints;
const assertFail = require("./helpers/assertFail");

contract("StatusContribution", (accounts) => {
    let multisigStatus;
    let multisigComunity;
    let multisigSecondarySell;
    let miniMeFactory;
    let sgt;
    let snt;
    let statusContribution;
    let contributionWallet;
    let devTokensHolder;
    let sgtExchanger;
    let dynamicCeiling;
    let sntPlaceHolder;

    const points = [ [ 1000000, web3.toWei(3) ],
                     [ 1001000, web3.toWei(13) ],
                     [ 1002000, web3.toWei(61000) ] ];
    const startBlock = 1000000;
    const stopBlock = 1003000;

    it("Should deploy Contribution contracts", async () => {
        multisigStatus = await MultisigWallet.new([ accounts[ 0 ] ], 1);
        multisigComunity = await MultisigWallet.new([ accounts[ 1 ] ], 1);
        multisigSecondarySell = await MultisigWallet.new([ accounts[ 2 ] ], 1);
        miniMeFactory = await MiniMeTokenFactory.new();
        sgt = await SGT.new(miniMeFactory.address);
        await sgt.generateTokens(accounts[ 0 ], 158854038);

        snt = await SNT.new(miniMeFactory.address);
        statusContribution = await StatusContributionMock.new();
        contributionWallet = await ContributionWallet.new(
            multisigStatus.address,
            stopBlock,
            statusContribution.address);
        devTokensHolder = await DevTokensHolder.new(
            statusContribution.address,
            snt.address);
        sgtExchanger = await SGTExchanger.new(sgt.address, snt.address);
        dynamicCeiling = await DynamicCeiling.new();

        await setHiddenPoints(dynamicCeiling, points);

        sntPlaceHolder = await SNTPlaceHolder.new(
            multisigComunity.adress,
            snt.address,
            statusContribution.address);

        await snt.changeController(statusContribution.address);
        await sgt.changeController(sgtExchanger.address);

        await statusContribution.initialize(
          snt.address,
          startBlock,
          stopBlock,
          dynamicCeiling.address,

          contributionWallet.address,

          devTokensHolder.address,

          multisigSecondarySell.address,
          sgt.address,

          sgtExchanger.address,
          158854038 * 2,

          sntPlaceHolder.address);
    });

    it("Check initial parameters", async () => {
        assert.equal(await snt.controller(), statusContribution.address);
        assert.equal(await sgt.controller(), sgtExchanger.address);
    });

    it("Checks that no body can buy before the sale starts", async () => {
        try {
            await snt.send(web3.toWei(1));
        } catch (error) {
            assertFail(error);
        }
    });

    it("Reveal a cap, move time to start of the ICO, and do the first buy", async () => {
        await dynamicCeiling.revealPoint(
                points[ 0 ][ 0 ],
                points[ 0 ][ 1 ],
                false,
                web3.sha3("pwd0"));

        await statusContribution.setMockedBlockNumber(1000000);

        await snt.sendTransaction({ value: web3.toWei(1), gas: 300000 });

        const balance = await snt.balanceOf(accounts[ 0 ]);

        assert.equal(web3.fromWei(balance), 1000);
    });

    it("Should return the remaining in the last transaction ", async () => {
        const initailBalance = await web3.eth.getBalance(accounts[ 0 ]);
        await snt.sendTransaction({ value: web3.toWei(5), gas: 300000 });
        const finalBalance = await web3.eth.getBalance(accounts[ 0 ]);

        const spended = web3.fromWei(initailBalance.sub(finalBalance)).toNumber();
        assert.isAbove(spended, 2);
        assert.isBelow(spended, 2.1);

        const totalCollected = await statusContribution.totalCollected();
        assert.equal(web3.fromWei(totalCollected), 3);

        const balanceContributionWallet = await web3.eth.getBalance(contributionWallet.address);
        assert.equal(web3.fromWei(balanceContributionWallet), 3);
    });

    it("Should reveal second cap and check that every that the limit is right", async () => {
        await dynamicCeiling.revealPoint(
                points[ 1 ][ 0 ],
                points[ 1 ][ 1 ],
                false,
                web3.sha3("pwd1"));

        await statusContribution.setMockedBlockNumber(1000500);

        const initailBalance = await web3.eth.getBalance(accounts[ 0 ]);
        await snt.sendTransaction({ value: web3.toWei(10), gas: 300000 });
        const finalBalance = await web3.eth.getBalance(accounts[ 0 ]);

        const spended = web3.fromWei(initailBalance.sub(finalBalance)).toNumber();
        assert.isAbove(spended, 5);
        assert.isBelow(spended, 5.1);

        const totalCollected = await statusContribution.totalCollected();
        assert.equal(web3.fromWei(totalCollected), 8);

        const balanceContributionWallet = await web3.eth.getBalance(contributionWallet.address);
        assert.equal(web3.fromWei(balanceContributionWallet), 8);
    });
});
