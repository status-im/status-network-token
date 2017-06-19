module.exports = async function(callback) {
    let gas_limit_error_thrown = false;
    try {
        await callback();
    } catch (error) {
        gas_limit_error_thrown = error.message.search('exceeds gas') > -1;
    }
    assert.ok(gas_limit_error_thrown, 'Exceeds gas limit must be returned');
}
