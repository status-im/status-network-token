module.exports = async function(callback) {
    let web3_error_thrown = false;
    try {
        await callback();
    } catch (error) {
        web3_error_thrown = error.message.search("invalid opcode") > -1;
    }
    assert.ok(web3_error_thrown, "Transaction should fail");
};
