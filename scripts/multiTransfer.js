const Web3 = require("web3");
const fs = require("fs");
const async = require("async");
// create an instance of web3 using the HTTP provider.
// NOTE in mist web3 is already available, so check first if its available before instantiating
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const BigNumber = require("bignumber.js");

const eth = web3.eth;

var sgtAbi = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"creationBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_newController","type":"address"}],"name":"changeController","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_blockNumber","type":"uint256"}],"name":"balanceOfAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_cloneTokenName","type":"string"},{"name":"_cloneDecimalUnits","type":"uint8"},{"name":"_cloneTokenSymbol","type":"string"},{"name":"_snapshotBlock","type":"uint256"},{"name":"_transfersEnabled","type":"bool"}],"name":"createCloneToken","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"parentToken","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"},{"name":"_amount","type":"uint256"}],"name":"generateTokens","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_blockNumber","type":"uint256"}],"name":"totalSupplyAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"transfersEnabled","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"parentSnapShotBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"},{"name":"_extraData","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"},{"name":"_amount","type":"uint256"}],"name":"destroyTokens","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_transfers","type":"uint256[]"},{"name":"_toEmpty","type":"bool"}],"name":"multiTransfer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tokenFactory","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_transfersEnabled","type":"bool"}],"name":"enableTransfers","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"controller","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_tokenFactory","type":"address"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_cloneToken","type":"address"},{"indexed":false,"name":"_snapshotBlock","type":"uint256"}],"name":"NewCloneToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Approval","type":"event"}];
var sgt = web3.eth.contract(sgtAbi).at("0xdd604fb9c5e6f738451126979bbc1c40b9961e2f");

/*
const transfers = [

    ["0x1234567890123456789012345678901234567890", 21.2],
    ["0x2345678901234567890123456789012345678901", 21.2],

    ///
];
*/

const multiple = 50;
const D160 = new BigNumber("10000000000000000000000000000000000000000", 16);

const gcb = (err, res) => {
    if (err) {
        console.log(`ERROR: ${ err }`);
    } else {
        console.log(JSON.stringify(res, null, 2));
    }
};

const loadCsv = (fileName, _cb) => {
    const cb = _cb || gcb;
    const transfers = [];
    fs.readFile(fileName, "utf8", (err, res) => {
        let i;
        if (err) return cb(err);
        const lines = res.split("\n");

        for (i = 0; i < lines.length; i += 1) {
            const fields = lines[ i ].split(",");
            if ((fields[ 1 ]) && (web3.isAddress(fields[ 1 ].trim())) && (Number(fields[ 2 ]))) {
                transfers.push([
                    fields[ 1 ].trim(),
                    Number(fields[ 2 ]),
                ]);
            } else {
                console.log(`Invalid Line #${ i } Addr: ${ fields[ 1 ] } Val: ${ fields[ 2 ] }`);
            }
        }
        cb(null, transfers);
    });
};

const multiSend = (transfers, _cb) => {
    const cb = _cb || gcb;
    let i;
    const packetTransfers = [];
    for (i = 0; i < transfers.length; i += 1) {
        packetTransfers.push(pack(transfers[ i ][ 0 ], transfers[ i ][ 1 ]));
    }

    let pos = 0;
    async.whilst(
        () => pos < packetTransfers.length,
        (cb1) => {
            const sendTransfers = packetTransfers.slice(pos, pos + multiple);
            pos += multiple;

/*
            setTimeout(() => {
                console.log(`Send Transaction: ${ sendTransfers.length }`);
                cb1();
            }, 10); */

            console.log("Transaction: " + sendTransfers.length);
            sgt.multiTransfer(sendTransfers, true, { from: eth.accounts[ 0 ], gas: 3700000 }, cb1);
        },
        cb);

    function pack(address, amount) {
        const addressNum = new BigNumber(address.substring(2), 16);
        const amountWei = new BigNumber(web3.toWei(amount));
        const v = D160.mul(amountWei).add(addressNum);
        return v.toString(10);
    }
};

const run = (cb) => {
    loadCsv("genesisDistribution.csv", (err, transfers) => {
        if (err) {
            cb(err);
            return;
        }
        multiSend(transfers, cb);
    });
};

run((err) => {
    if (err) {
        console.log(err);
    } else {
        console.log("terminated succefully");
    }
});
