module.exports = async function(callback) {
    let gas_error_thrown = false;
    try {
        await callback();
    } catch (error) {
        gas_error_thrown = error.message.search('of gas') > -1;
    }
    assert.ok(gas_error_thrown, 'Out of gas error must be returned');
}
