module.exports = async (callback) => {
    let web3_error_thrown = false;
    try {
        await callback();
    } catch (error) {
        if (error.message.search("invalid opcode")) web3_error_thrown = true;
    }
    assert.ok(web3_error_thrown, "Transaction should fail");
};
