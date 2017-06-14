// Simulate a full contribution
const DynamicCeiling = artifacts.require("DynamicCeiling");

const setHiddenCurves = require("./helpers/hiddenCurves.js").setHiddenCurves;

contract("DynamicCeiling", (accounts) => {
    let dynamicCeiling;

    const curves = [
        [1000000, web3.toWei(3), 30, 10**12],
        [1010000, web3.toWei(8), 30, 10**12],
        [1020000, web3.toWei(15), 30, 10**12],
    ];

    const checkPoint = async (block, idx, limit, slopeFactor, collectMinimum) => {
        res = await dynamicCeiling.curve(block);
        assert.equal(res[0].toNumber(), idx);
        assert.equal(res[1].toNumber(), limit);
        assert.equal(res[2].toNumber(), slopeFactor);
        assert.equal(res[3].toNumber(), collectMinimum);
    };

    it("Should deploy dynamicCeiling", async () => {
        dynamicCeiling = await DynamicCeiling.new(accounts[0]);
    });

    it("Cap should be 0 before curves are set", async () => {
        await checkPoint(0, 0,0,0,0);
    });

    it("Should set the curves", async () => {
        await setHiddenCurves(dynamicCeiling, curves);
        const nCurves = await dynamicCeiling.nCurves();
        assert.equal(nCurves.toNumber(), 10);
    });

    it("Cap should be 0 before curves are revealed", async () => {
        await checkPoint(0, 0,0,0,0);
        await checkPoint(10, 0,0,0,0);
        await checkPoint(15, 0,0,0,0);
        await checkPoint(20, 0,0,0,0);
        await checkPoint(30, 0,0,0,0);
        await checkPoint(55, 0,0,0,0);
        await checkPoint(676, 0,0,0,0);
        await checkPoint(5555, 0,0,0,0);
        await checkPoint(10**8, 0,0,0,0);
    });

    it("Should reveal 1st curve", async () => {
        await dynamicCeiling.revealCurve(
            curves[0][0],
            curves[0][1],
            curves[0][2],
            curves[0][3],
            false,
            web3.sha3("pwd0"));

        assert.equal(await dynamicCeiling.revealedCurves(), 1);
        assert.equal(await dynamicCeiling.allRevealed(), false);
    });

    it("Check limits after revealed 1st curve", async () => {
        await checkPoint(0, 0,0,0,0);
        await checkPoint(1000000 - 1 , 0,0,0,0);
        await checkPoint(1000000, 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1000001, 0,curves[0][1],curves[0][2],curves[0][3]);
    });

    it("Should reveal 2nd curve", async () => {
        await dynamicCeiling.revealCurve(
            curves[1][0],
            curves[1][1],
            curves[1][2],
            curves[1][3],
            false,
            web3.sha3("pwd1"));

        assert.equal(await dynamicCeiling.revealedCurves(), 2);
        assert.equal(await dynamicCeiling.allRevealed(), false);
    });

    it("Check limits after revealed 2nd curve", async () => {
        await checkPoint(0, 0,0,0,0);
        await checkPoint(1000000 - 1 , 0,0,0,0);
        await checkPoint(1000000     , 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1000000 + 1 , 0,curves[0][1],curves[0][2],curves[0][3]);

        await checkPoint(1010000 - 1, 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1010000    , 1,curves[1][1],curves[1][2],curves[1][3]);
        await checkPoint(1010000 + 1, 1,curves[1][1],curves[1][2],curves[1][3]);
    });

    it("Should reveal last curve", async () => {
        await dynamicCeiling.revealCurve(
            curves[2][0],
            curves[2][1],
            curves[2][2],
            curves[2][3],
            true,
            web3.sha3("pwd2"));

        assert.equal(await dynamicCeiling.revealedCurves(), 3);
        assert.equal(await dynamicCeiling.allRevealed(), true);
    });

    it("Check limits after revealed 3rd curve", async () => {
        await checkPoint(0, 0,0,0,0);
        await checkPoint(1000000 - 1 , 0,0,0,0);
        await checkPoint(1000000     , 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1000000 + 1 , 0,curves[0][1],curves[0][2],curves[0][3]);

        await checkPoint(1010000 - 1, 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1010000    , 1,curves[1][1],curves[1][2],curves[1][3]);
        await checkPoint(1010000 + 1, 1,curves[1][1],curves[1][2],curves[1][3]);

        await checkPoint(1020000 - 1, 1,curves[1][1],curves[1][2],curves[1][3]);
        await checkPoint(1020000    , 2,curves[2][1],curves[2][2],curves[2][3]);
        await checkPoint(1020000 + 1, 2,curves[2][1],curves[2][2],curves[2][3]);
    });

    it("Should move the curves 10 blocks", async () => {
        const offset = 100;
        await dynamicCeiling.delayCurves(1, offset);

        await checkPoint(0, 0,0,0,0);
        await checkPoint(1000000 - 1 , 0,0,0,0);
        await checkPoint(1000000     , 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1000000 + 1 , 0,curves[0][1],curves[0][2],curves[0][3]);

        await checkPoint(1010000 - 1 + offset, 0,curves[0][1],curves[0][2],curves[0][3]);
        await checkPoint(1010000     + offset, 1,curves[1][1],curves[1][2],curves[1][3]);
        await checkPoint(1010000 + 1 + offset, 1,curves[1][1],curves[1][2],curves[1][3]);

        await checkPoint(1020000 - 1 + offset, 1,curves[1][1],curves[1][2],curves[1][3]);
        await checkPoint(1020000     + offset, 2,curves[2][1],curves[2][2],curves[2][3]);
        await checkPoint(1020000 + 1 + offset, 2,curves[2][1],curves[2][2],curves[2][3]);
    });

    it("Should deploy dynamicCeiling", async () => {
        dynamicCeiling = await DynamicCeiling.new(accounts[0]);
    });

    it("Should set the curves", async () => {
        await setHiddenCurves(dynamicCeiling, curves);
        assert.equal(await dynamicCeiling.nCurves(), 10);
    });

    it("Should reveal multiple curves", async () => {
        await dynamicCeiling.revealMulti(
            [
                curves[0][0],
                curves[1][0],
                curves[2][0],
            ],
            [
                curves[0][1],
                curves[1][1],
                curves[2][1],
            ],
            [
                curves[0][2],
                curves[1][2],
                curves[2][2],
            ],
            [
                curves[0][3],
                curves[1][3],
                curves[2][3],
            ],
            [
                false,
                false,
                true,
            ],
            [
                web3.sha3("pwd0"),
                web3.sha3("pwd1"),
                web3.sha3("pwd2"),
            ]
        );

        assert.equal(await dynamicCeiling.revealedCurves(), 3);
        assert.equal(await dynamicCeiling.allRevealed(), true);
    });

});
