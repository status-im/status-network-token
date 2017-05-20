module.exports = (error) => {
    if (error.message.search("invalid opcode")) return;
    assert.ok(false, "Transaction should fail");
};
