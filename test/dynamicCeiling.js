// Simulate a full contribution
const DynamicCeiling = artifacts.require("DynamicCeiling");

const setHiddenPoints = require("./helpers/hiddenPoints.js").setHiddenPoints;

contract("DynamicCeiling", (accounts) => {
    let dynamicCeiling;

    const points = [
        [web3.toWei(1000)],
        [web3.toWei(21000)],
        [web3.toWei(61000)],
    ];

    it("Should deploy dynamicCeiling", async () => {
        dynamicCeiling = await DynamicCeiling.new(accounts[0], accounts[0]);

        assert.equal(await dynamicCeiling.currentIndex(), 0);
    });

    it("Cap should be 0 before points are set", async () => {
        assert.equal(await dynamicCeiling.toCollect.call(0), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(10)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(15)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(20)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(30)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(55)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(676)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(5555)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(10**8)), 0);

        assert.equal(await dynamicCeiling.currentIndex(), 0);
    });

    it("Should set the points", async () => {
        await setHiddenPoints(dynamicCeiling, points);
        assert.equal(await dynamicCeiling.nPoints(), 10);
    });

    it("Cap should be 0 before points are revealed", async () => {
        assert.equal(await dynamicCeiling.toCollect.call('0'), '0');
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(10)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(15)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(20)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(30)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(55)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(676)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(5555)), 0);
        assert.equal(await dynamicCeiling.toCollect.call(web3.toWei(10**8)), 0);

        assert.equal(await dynamicCeiling.currentIndex(), 0);
    });

    it("Should reveal 1st point", async () => {
        await dynamicCeiling.revealPoint(
            points[0][0],
            false,
            web3.sha3("pwd0"));

        assert.equal(await dynamicCeiling.revealedPoints(), 1);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '0');
        assert.equal(await dynamicCeiling.allRevealed(), false);
    });

    it("Check limits after revealed 1st point", async () => {
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '0');
        assert.equal((await dynamicCeiling.toCollect.call(0)).toFixed(), '33333333333333333333');

        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(10))).toFixed(), '33000000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(15))).toFixed(), '32833333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(20))).toFixed(), '32666666666666666666');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(30))).toFixed(), '32333333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(55))).toFixed(), '31500000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(676))).toFixed(), '10800000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(999))).toFixed(), '33333333333333333');

        assert.equal((await dynamicCeiling.toCollect.call('999999999998999999999')).toFixed(), '1000000001');
        assert.equal((await dynamicCeiling.toCollect.call('999999999999000000000')).toFixed(), '1000000000');
        assert.equal((await dynamicCeiling.toCollect.call('999999999999999999999')).toFixed(), '1');

        await dynamicCeiling.toCollect(points[0][0]);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '0');
        assert.equal((await dynamicCeiling.toCollect.call(points[0][0])).toFixed(), '0');
    });

    it("Should reveal 2nd point", async () => {
        await dynamicCeiling.revealPoint(
            points[1][0],
            false,
            web3.sha3("pwd1"));

        assert.equal(await dynamicCeiling.revealedPoints(), 2);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '0');
        assert.equal(await dynamicCeiling.allRevealed(), false);
    });

    it("Check limits after revealed 2nd point", async () => {
        await dynamicCeiling.toCollect(points[0][0]);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '1');
        assert.equal((await dynamicCeiling.toCollect.call(points[0][0])).toFixed(), '666666666666666666666')

        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(1010))).toFixed(), '666333333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(1015))).toFixed(), '666166666666666666666');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(1020))).toFixed(), '666000000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(1030))).toFixed(), '665666666666666666666');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(1055))).toFixed(), '664833333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(10676))).toFixed(), '344133333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(10999))).toFixed(), '333366666666666666666');

        assert.equal((await dynamicCeiling.toCollect.call('20999999999998999999999')).toFixed(), '1000000001');
        assert.equal((await dynamicCeiling.toCollect.call('20999999999999000000000')).toFixed(), '1000000000');
        assert.equal((await dynamicCeiling.toCollect.call('20999999999999999999999')).toFixed(), '1');

        await dynamicCeiling.toCollect(points[1][0]);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '1');
        assert.equal((await dynamicCeiling.toCollect.call(points[1][0])).toFixed(), '0');
    });

    it("Should reveal last point", async () => {
        await dynamicCeiling.revealPoint(
            points[2][0],
            true,
            web3.sha3("pwd2"));

        assert.equal(await dynamicCeiling.revealedPoints(), 3);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '1');
        assert.equal(await dynamicCeiling.allRevealed(), true);
    });

    it("Check limits after revealed 3rd point", async () => {
        await dynamicCeiling.toCollect(points[1][0]);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '2');
        assert.equal((await dynamicCeiling.toCollect.call(points[1][0])).toFixed(), '1333333333333333333333');

        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21010))).toFixed(), '1333000000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21015))).toFixed(), '1332833333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21020))).toFixed(), '1332666666666666666666');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21030))).toFixed(), '1332333333333333333333');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21055))).toFixed(), '1331500000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21676))).toFixed(), '1310800000000000000000');
        assert.equal((await dynamicCeiling.toCollect.call(web3.toWei(21999))).toFixed(), '1300033333333333333333');

        assert.equal((await dynamicCeiling.toCollect.call('60999999999998999999999')).toFixed(), '1000000001');
        assert.equal((await dynamicCeiling.toCollect.call('60999999999999000000000')).toFixed(), '1000000000');
        assert.equal((await dynamicCeiling.toCollect.call('60999999999999999999999')).toFixed(), '1');

        await dynamicCeiling.toCollect(points[2][0]);
        assert.equal((await dynamicCeiling.currentIndex()).toFixed(), '2');
        assert.equal((await dynamicCeiling.toCollect.call(points[2][0])).toFixed(), '0');
    });
});
