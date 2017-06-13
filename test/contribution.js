// Simulate a full contribution

const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const SGT = artifacts.require("SGTMock");
const SNT = artifacts.require("SNTMock");
const MultiSigWallet = artifacts.require("MultiSigWallet");
const ContributionWallet = artifacts.require("ContributionWallet");
const StatusContributionMock = artifacts.require("StatusContributionMock");
const DevTokensHolder = artifacts.require("DevTokensHolderMock");
const SGTExchanger = artifacts.require("SGTExchanger");
const DynamicCeiling = artifacts.require("DynamicCeiling");
const SNTPlaceHolderMock = artifacts.require("SNTPlaceHolderMock");

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
    let lim;
    let cur;
    const divs = 30;

    const points = [
        [1000000, web3.toWei(3)],
        [1010000, web3.toWei(13)],
        [1020000, web3.toWei(15)],
    ];
    const startBlock = 1000000;
    const sgtPreferenceBlocks = 2000;
    const endBlock = 1030000;
    const sgtLimit = web3.toWei(0.1);

    it("Should deploy Contribution contracts", async () => {
        multisigStatus = await MultiSigWallet.new([accounts[0]], 1);
        multisigComunity = await MultiSigWallet.new([accounts[1]], 1);
        multisigSecondarySell = await MultiSigWallet.new([accounts[2]], 1);
        multisigDevs = await MultiSigWallet.new([accounts[3]], 1);
        miniMeFactory = await MiniMeTokenFactory.new();
        sgt = await SGT.new(miniMeFactory.address);
        await sgt.generateTokens(accounts[4], 2500);
        await sgt.generateTokens(accounts[0], 2500);

        snt = await SNT.new(miniMeFactory.address);
        statusContribution = await StatusContributionMock.new();
        contributionWallet = await ContributionWallet.new(
            multisigStatus.address,
            endBlock,
            statusContribution.address);
        devTokensHolder = await DevTokensHolder.new(
            multisigDevs.address,
            statusContribution.address,
            snt.address);
        sgtExchanger = await SGTExchanger.new(sgt.address, snt.address, statusContribution.address);
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
            endBlock,
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

    it("Add 2 guaranteed addresses ", async () => {
        await statusContribution.setGuaranteedAddress(accounts[7], web3.toWei(1));
        await statusContribution.setGuaranteedAddress(accounts[8], web3.toWei(2));

        const permited7 = await statusContribution.guaranteedBuyersLimit(accounts[7]);
        const permited8 = await statusContribution.guaranteedBuyersLimit(accounts[8]);

        assert.equal(web3.fromWei(permited7).toNumber(), 1);
        assert.equal(web3.fromWei(permited8).toNumber(), 2);
    });

    it("Reveal a point, move time to start of the ICO, and do the first buy", async () => {
        await dynamicCeiling.revealPoint(
            points[0][0],
            points[0][1],
            false,
            web3.sha3("pwd0"));

        await statusContribution.setMockedBlockNumber(1000000);
        await sgt.setMockedBlockNumber(1000000);
        await snt.setMockedBlockNumber(1000000);

        lim = 3;
        cur = 0;

        await snt.sendTransaction({value: web3.toWei(1), gas: 300000, gasPrice: "20000000000", from: accounts[0]});

        const b = Math.min(1, ((lim - cur) / divs));
        cur += b;

        const balance = await snt.balanceOf(accounts[0]);

        assert.equal(web3.fromWei(balance).toNumber(), b * 10000);
    });

    it("Should not allow transfers of no SGT holders in the SGT preference period", async () => {
        try {
            await snt.sendTransaction({value: web3.toWei(1), gas: 300000, gasPrice: "20000000000", from: accounts[1]});
            throw new Error("Not throwed");
        } catch (error) {
            assertFail(error);
        }
    });

    it("Should not allow exceed sgtLimit", async () => {
        try {
            await snt.sendTransaction({value: web3.toWei(1), gas: 300000, gasPrice: "20000000000", from: accounts[0]});
            throw new Error("Not throwed");
        } catch (error) {
            assertFail(error);
        }
    });

    it("Should return the remaining in the last transaction ", async () => {
        await statusContribution.setMockedBlockNumber(1005000);
        await sgt.setMockedBlockNumber(1005000);
        await snt.setMockedBlockNumber(1005000);
        const initialBalance = await web3.eth.getBalance(accounts[0]);
        await snt.sendTransaction({value: web3.toWei(5), gas: 300000, gasPrice: "20000000000"});
        const finalBalance = await web3.eth.getBalance(accounts[0]);

        const b = Math.min(5, ((lim - cur) / divs));
        cur += b;

        const spent = web3.fromWei(initialBalance.sub(finalBalance)).toNumber();
        assert.isAbove(spent, b);
        assert.isBelow(spent, b + 0.02);

        const totalCollected = await statusContribution.totalCollected();
        assert.equal(web3.fromWei(totalCollected), cur);

        const balanceContributionWallet = await web3.eth.getBalance(contributionWallet.address);
        assert.equal(web3.fromWei(balanceContributionWallet), cur);
    });

    it("Should reveal second point and check that every that the limit is right", async () => {
        await dynamicCeiling.revealPoint(
            points[1][0],
            points[1][1],
            false,
            web3.sha3("pwd1"));

        await statusContribution.setMockedBlockNumber(1005000);
        await sgt.setMockedBlockNumber(1005000);
        await snt.setMockedBlockNumber(1005000);

        const initialBalance = await web3.eth.getBalance(accounts[0]);
        await snt.sendTransaction({value: web3.toWei(10), gas: 300000, gasPrice: "20000000000"});
        const finalBalance = await web3.eth.getBalance(accounts[0]);

        lim = 8;
        const b = Math.min(5, ((lim - cur) / divs));
        cur += b;

        const spent = web3.fromWei(initialBalance.sub(finalBalance)).toNumber();
        assert.isAbove(spent, b);
        assert.isBelow(spent, b + 0.02);

        const totalCollected = await statusContribution.totalCollected();
        assert.equal(web3.fromWei(totalCollected), cur);

        const balanceContributionWallet = await web3.eth.getBalance(contributionWallet.address);
        assert.equal(web3.fromWei(balanceContributionWallet), cur);
    });

    it("Should reveal last point, fill the collaboration", async () => {
        await dynamicCeiling.revealPoint(
            points[2][0],
            points[2][1],
            true,
            web3.sha3("pwd2"));

        await statusContribution.setMockedBlockNumber(1025000);
        await sgt.setMockedBlockNumber(1025000);
        await snt.setMockedBlockNumber(1025000);

        const initialBalance = await web3.eth.getBalance(accounts[0]);
        await statusContribution.proxyPayment(
            accounts[1],
            {value: web3.toWei(15), gas: 300000, from: accounts[0], gasPrice: "20000000000"});

        lim = 15;
        const b = Math.min(5, ((lim - cur) / divs));
        cur += b;

        const finalBalance = await web3.eth.getBalance(accounts[0]);

        const balance1 = await snt.balanceOf(accounts[1]);

        assert.equal(web3.fromWei(balance1).toNumber(), b * 10000);

        const spent = web3.fromWei(initialBalance.sub(finalBalance)).toNumber();
        assert.isAbove(spent, b);
        assert.isBelow(spent, b + 0.02);

        const totalCollected = await statusContribution.totalCollected();
        assert.equal(web3.fromWei(totalCollected), cur);

        const balanceContributionWallet = await web3.eth.getBalance(contributionWallet.address);
        assert.equal(web3.fromWei(balanceContributionWallet), cur);

        while (cur < 14) {
            await statusContribution.proxyPayment(
                accounts[1],
                {value: web3.toWei(15), gas: 300000, from: accounts[0], gasPrice: "20000000000"});

            const b2 = Math.min(5, ((lim - cur) / divs));
            cur += b2;

            const balanceContributionWallet2 =
                await web3.eth.getBalance(contributionWallet.address);
            assert.isBelow(Math.abs(web3.fromWei(balanceContributionWallet2).toNumber() - cur), 0.0001);
        }
    });

    it("Should not allow transfers in contribution period", async () => {
        try {
            await snt.transfer(accounts[4], web3.toWei(1000));
        } catch (error) {
            assertFail(error);
        }
    });

    it("Guaranteed address should still be able to buy", async () => {
        await snt.sendTransaction({value: web3.toWei(3), gas: 300000, from: accounts[7]});
        await snt.sendTransaction({value: web3.toWei(3), gas: 300000, from: accounts[8]});

        const balance7 = await snt.balanceOf(accounts[7]);
        const balance8 = await snt.balanceOf(accounts[8]);

        assert.equal(web3.fromWei(balance7).toNumber(), 10000);
        assert.equal(web3.fromWei(balance8).toNumber(), 20000);
    });

    it("Should finalize", async () => {
        await statusContribution.finalize();

        const totalSupply = await snt.totalSupply();

        assert.isBelow(web3.fromWei(totalSupply).toNumber() - (180000 / 0.46), 0.01);

        const balanceSGT = await snt.balanceOf(sgtExchanger.address);
        assert.equal(balanceSGT.toNumber(), totalSupply.mul(0.05).toNumber());

        const balanceDevs = await snt.balanceOf(devTokensHolder.address);
        assert.equal(balanceDevs.toNumber(), totalSupply.mul(0.20).toNumber());

        const balanceSecondary = await snt.balanceOf(multisigSecondarySell.address);
        assert.equal(balanceSecondary.toNumber(), totalSupply.mul(0.29).toNumber());
    });

    it("Should move the Ether to the final multisig", async () => {
        await multisigStatus.submitTransaction(
            contributionWallet.address,
            0,
            contributionWallet.contract.withdraw.getData());

        const balance = await web3.eth.getBalance(multisigStatus.address);

        assert.isBelow(Math.abs(web3.fromWei(balance).toNumber() - (cur+3)), 0.00001);
    });

    it("Should be able to exchange sgt by snt", async () => {
        await sgtExchanger.collect({from: accounts[4]});

        const balance = await snt.balanceOf(accounts[4]);
        const totalSupply = await snt.totalSupply();

        assert.equal(totalSupply.mul(0.025).toNumber(), balance.toNumber());
    });

    it("Should not allow transfers in the 1 week period", async () => {
        try {
            await snt.transfer(accounts[4], web3.toWei(1000));
        } catch (error) {
            assertFail(error);
        }
    });

    it("Should allow transfers after 1 week period", async () => {
        const t = Math.floor(new Date().getTime() / 1000) + (86400 * 7) + 1000;
        await sntPlaceHolder.setMockedTime(t);

        await snt.transfer(accounts[5], web3.toWei(1000));

        const balance2 = await snt.balanceOf(accounts[5]);

        assert.equal(web3.fromWei(balance2).toNumber(), 1000);
    });

    it("Devs should not allow transfers before 6 months", async () => {
        const t = Math.floor(new Date().getTime() / 1000) + (86400 * 7) + 1000;
        await devTokensHolder.setMockedTime(t);

        try {
            await multisigDevs.submitTransaction(
                devTokensHolder.address,
                0,
                devTokensHolder.contract.collectTokens.getData(),
                {from: accounts[3]});
        } catch (error) {
            assertFail(error);
        }
    });

    it("Devs Should be able to extract 1/2 after a year", async () => {
        const t = Math.floor(new Date().getTime() / 1000) + (86400 * 360);
        await devTokensHolder.setMockedTime(t);

        const totalSupply = await snt.totalSupply();

        await multisigDevs.submitTransaction(
            devTokensHolder.address,
            0,
            devTokensHolder.contract.collectTokens.getData(),
            {from: accounts[3]});

        const balance = await snt.balanceOf(multisigDevs.address);

        const calcTokens = web3.fromWei(totalSupply.mul(0.20).mul(0.5)).toNumber();
        const realTokens = web3.fromWei(balance).toNumber();

        assert.isBelow(realTokens - calcTokens, 0.1);
    });

    it("Devs Should be able to extract every thing after 2 year", async () => {
        const t = Math.floor(new Date().getTime() / 1000) + (86400 * 360 * 2);
        await devTokensHolder.setMockedTime(t);

        const totalSupply = await snt.totalSupply();

        await multisigDevs.submitTransaction(
            devTokensHolder.address,
            0,
            devTokensHolder.contract.collectTokens.getData(),
            {from: accounts[3]});

        const balance = await snt.balanceOf(multisigDevs.address);

        const calcTokens = web3.fromWei(totalSupply.mul(0.20)).toNumber();
        const realTokens = web3.fromWei(balance).toNumber();

        assert.equal(calcTokens, realTokens);
    });

    it("SNT's Controller should be upgradeable", async () => {
        await multisigComunity.submitTransaction(
            sntPlaceHolder.address,
            0,
            sntPlaceHolder.contract.changeController.getData(accounts[6]),
            {from: accounts[1]});

        const controller = await snt.controller();

        assert.equal(controller, accounts[6]);
    });
});
