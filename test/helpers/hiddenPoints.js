exports.setHiddenPoints = async (dynamicCeiling, points) => {
    const hashes = [];
    let i = 0;
    for (let p of points) {
        const h = await dynamicCeiling.calculateHash(
            p[1],
            i === points.length - 1,
            web3.sha3(`pwd${ i }`));
        hashes.push(h);
        i += 1;
    }
    for (; i < 10; i += 1) {
        hashes.push(web3.sha3(`pwd${ i }`));
    }
    await dynamicCeiling.setHiddenPoints(hashes);
};
