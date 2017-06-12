// Simulate a full contribution
const DynamicCeiling = artifacts.require("DynamicCeiling");

const setHiddenCurves = require("./helpers/hiddenCurves.js").setHiddenCurves;

contract("DynamicCeiling", () => {
    let dynamicCeiling;

    const curves = [
        [web3.toWei(1000)],
        [web3.toWei(21000)],
        [web3.toWei(61000)],
    ];

    it("Should deploy dynamicCeiling", async () => {
        dynamicCeiling = await DynamicCeiling.new();
    });

    it("Cap should be 0 before curves are set", async () => {
        assert.equal(await dynamicCeiling.toCollect(0), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(10)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(15)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(20)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(30)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(55)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(676)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(5555)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(10**8)), 0);
    });

    it("Should set the curves", async () => {
        await setHiddenCurves(dynamicCeiling, curves);

        assert.equal(await dynamicCeiling.nCurves(), 10);
    });

    it("Cap should be 0 before curves are revealed", async () => {
        assert.equal(await dynamicCeiling.toCollect(0), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(10)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(15)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(20)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(30)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(55)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(676)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(5555)), 0);
        assert.equal(await dynamicCeiling.toCollect(web3.toWei(10**8)), 0);
    });

    it("Should reveal 1st curve", async () => {
        await dynamicCeiling.revealCurve(
            curves[0][0],
            false,
            web3.sha3("pwd0"));

        assert.equal(await dynamicCeiling.revealedCurves(), 1);
        assert.equal(await dynamicCeiling.allRevealed(), false);
    });

    it("Check limits after revealed 1st curve", async () => {
        assert.equal((await dynamicCeiling.toCollect(0)).toString(10), '33333333333333333333');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(10))).toString(10), '33000000000000000000');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(15))).toString(10), '32833333333333333333');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(20))).toString(10), '32666666666666666666');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(30))).toString(10), '32333333333333333333');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(55))).toString(10), '31500000000000000000');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(676))).toString(10), '10800000000000000000');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(999))).toString(10), '33333333333333333');
        assert.equal((await dynamicCeiling.toCollect('999999999998999999999')).toString(10), '1000000001');
        assert.equal((await dynamicCeiling.toCollect('999999999999000000000')).toString(10), '1000000000');
        assert.equal((await dynamicCeiling.toCollect('999999999999999999999')).toString(10), '1');
        assert.equal((await dynamicCeiling.toCollect(web3.toWei(1000))).toString(10), '0');
    });

    // it("Should reveal 2nd curve", async () => {
    //     await dynamicCeiling.revealCurve(
    //         curves[1][0],
    //         false,
    //         web3.sha3("pwd1"));

    //     assert.equal(await dynamicCeiling.revealedCurves(), 2);
    //     assert.equal(await dynamicCeiling.allRevealed(), false);
    // });

    // it("Check limits after revealed 2nd curve", async () => {
    //     assert.equal(await dynamicCeiling.toCollect(99999), 0);
    //     assert.equal((await dynamicCeiling.toCollect(1000000)).toString(10), web3.toWei(1000));
    //     assert.equal((await dynamicCeiling.toCollect(1000001)).toString(10), web3.toWei(1020));

    //     assert.equal((await dynamicCeiling.toCollect(1000999)).toString(10), web3.toWei(20980));
    //     assert.equal((await dynamicCeiling.toCollect(1001000)).toString(10), web3.toWei(21000));
    //     assert.equal((await dynamicCeiling.toCollect(1001001)).toString(10), web3.toWei(21000));

    //     assert.equal((await dynamicCeiling.toCollect(1001999)).toString(10), web3.toWei(21000));
    //     assert.equal((await dynamicCeiling.toCollect(1002000)).toString(10), web3.toWei(21000));
    //     assert.equal((await dynamicCeiling.toCollect(1002001)).toString(10), web3.toWei(21000));
    // });

    // it("Should reveal last curve", async () => {
    //     await dynamicCeiling.revealCurve(
    //         curves[2][0],
    //         true,
    //         web3.sha3("pwd2"));

    //     assert.equal(await dynamicCeiling.revealedCurves(), 3);
    //     assert.equal(await dynamicCeiling.allRevealed(), true);
    // });

    // it("Check limits after revealed 3rd curve", async () => {
    //     assert.equal(await dynamicCeiling.toCollect(99999), 0);
    //     assert.equal((await dynamicCeiling.toCollect(1000000)).toString(10), web3.toWei(1000));
    //     assert.equal((await dynamicCeiling.toCollect(1000001)).toString(10), web3.toWei(1020));

    //     assert.equal((await dynamicCeiling.toCollect(1000999)).toString(10), web3.toWei(20980));
    //     assert.equal((await dynamicCeiling.toCollect(1001000)).toString(10), web3.toWei(21000));
    //     assert.equal((await dynamicCeiling.toCollect(1001001)).toString(10), web3.toWei(21040));

    //     assert.equal((await dynamicCeiling.toCollect(1001999)).toString(10), web3.toWei(60960));
    //     assert.equal((await dynamicCeiling.toCollect(1002000)).toString(10), web3.toWei(61000));
    //     assert.equal((await dynamicCeiling.toCollect(1002001)).toString(10), web3.toWei(61000));
    // });
});
