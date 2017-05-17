// Simulate a full contribution
const DynamicHiddenCap = artifacts.require("DynamicHiddenCap");

const setHiddenPoints = require("./helpers/hiddenPoints.js").setHiddenPoints;

contract("DynamicHiddenCap", () => {
    let dynamicHiddenCap;

    const points = [ [ 1000000, web3.toWei(1000) ],
        [ 1001000, web3.toWei(21000) ],
        [ 1002000, web3.toWei(61000) ] ];

    it("Should deploy dynamicHiddenCap", async () => {
        dynamicHiddenCap = await DynamicHiddenCap.new();
    });

    it("Cap should be 0 before points are set", async () => {
        assert.equal(await dynamicHiddenCap.cap(99999), 0);
        assert.equal(await dynamicHiddenCap.cap(100000), 0);
        assert.equal(await dynamicHiddenCap.cap(100001), 0);
        assert.equal(await dynamicHiddenCap.cap(100999), 0);
        assert.equal(await dynamicHiddenCap.cap(101000), 0);
        assert.equal(await dynamicHiddenCap.cap(101001), 0);
        assert.equal(await dynamicHiddenCap.cap(101999), 0);
        assert.equal(await dynamicHiddenCap.cap(102000), 0);
        assert.equal(await dynamicHiddenCap.cap(102001), 0);
    });

    it("Should set the points", async () => {
        await setHiddenPoints(dynamicHiddenCap, points);

        assert.equal(await dynamicHiddenCap.nPoints(), 10);
    });

    it("Cap should be 0 before points are revealed", async () => {
        assert.equal(await dynamicHiddenCap.cap(99999), 0);
        assert.equal(await dynamicHiddenCap.cap(1000000), 0);
        assert.equal(await dynamicHiddenCap.cap(1000001), 0);
        assert.equal(await dynamicHiddenCap.cap(1000999), 0);
        assert.equal(await dynamicHiddenCap.cap(1001000), 0);
        assert.equal(await dynamicHiddenCap.cap(1001001), 0);
        assert.equal(await dynamicHiddenCap.cap(1001999), 0);
        assert.equal(await dynamicHiddenCap.cap(1002000), 0);
        assert.equal(await dynamicHiddenCap.cap(1002001), 0);
    });

    it("Should reveal 1st point", async () => {
        await dynamicHiddenCap.revealPoint(
                points[ 0 ][ 0 ],
                points[ 0 ][ 1 ],
                false,
                web3.sha3("pwd0"));

        assert.equal(await dynamicHiddenCap.revealedPoints(), 1);
        assert.equal(await dynamicHiddenCap.allRevealed(), false);
    });

    it("Check limits after revealed 1st point", async () => {
        assert.equal(await dynamicHiddenCap.cap(99999), 0);
        assert.equal((await dynamicHiddenCap.cap(1000000)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1000001)).toString(10), web3.toWei(1000));

        assert.equal((await dynamicHiddenCap.cap(1000999)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1001000)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1001001)).toString(10), web3.toWei(1000));

        assert.equal((await dynamicHiddenCap.cap(1001999)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1002000)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1002001)).toString(10), web3.toWei(1000));
    });

    it("Should reveal 2nd point", async () => {
        await dynamicHiddenCap.revealPoint(
                points[ 1 ][ 0 ],
                points[ 1 ][ 1 ],
                false,
                web3.sha3("pwd1"));

        assert.equal(await dynamicHiddenCap.revealedPoints(), 2);
        assert.equal(await dynamicHiddenCap.allRevealed(), false);
    });

    it("Check limits after revealed 1st point", async () => {
        assert.equal(await dynamicHiddenCap.cap(99999), 0);
        assert.equal((await dynamicHiddenCap.cap(1000000)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1000001)).toString(10), web3.toWei(1020));

        assert.equal((await dynamicHiddenCap.cap(1000999)).toString(10), web3.toWei(20980));
        assert.equal((await dynamicHiddenCap.cap(1001000)).toString(10), web3.toWei(21000));
        assert.equal((await dynamicHiddenCap.cap(1001001)).toString(10), web3.toWei(21000));

        assert.equal((await dynamicHiddenCap.cap(1001999)).toString(10), web3.toWei(21000));
        assert.equal((await dynamicHiddenCap.cap(1002000)).toString(10), web3.toWei(21000));
        assert.equal((await dynamicHiddenCap.cap(1002001)).toString(10), web3.toWei(21000));
    });

    it("Should reveal last point", async () => {
        await dynamicHiddenCap.revealPoint(
                points[ 2 ][ 0 ],
                points[ 2 ][ 1 ],
                true,
                web3.sha3("pwd2"));

        assert.equal(await dynamicHiddenCap.revealedPoints(), 3);
        assert.equal(await dynamicHiddenCap.allRevealed(), true);
    });

    it("Check limits after revealed 1st point", async () => {
        assert.equal(await dynamicHiddenCap.cap(99999), 0);
        assert.equal((await dynamicHiddenCap.cap(1000000)).toString(10), web3.toWei(1000));
        assert.equal((await dynamicHiddenCap.cap(1000001)).toString(10), web3.toWei(1020));

        assert.equal((await dynamicHiddenCap.cap(1000999)).toString(10), web3.toWei(20980));
        assert.equal((await dynamicHiddenCap.cap(1001000)).toString(10), web3.toWei(21000));
        assert.equal((await dynamicHiddenCap.cap(1001001)).toString(10), web3.toWei(21040));

        assert.equal((await dynamicHiddenCap.cap(1001999)).toString(10), web3.toWei(60960));
        assert.equal((await dynamicHiddenCap.cap(1002000)).toString(10), web3.toWei(61000));
        assert.equal((await dynamicHiddenCap.cap(1002001)).toString(10), web3.toWei(61000));
    });
});
