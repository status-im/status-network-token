module.exports = async function(callback) {
    let jump_error_thrown = false;
    try {
        await callback();
    } catch (error) {
        jump_error_thrown = error.message.search('invalid JUMP') > -1;
    }
    assert.ok(jump_error_thrown, 'Invalid JUMP error must be returned');
}
