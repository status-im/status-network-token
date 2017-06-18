module.exports = function(error) {
    assert.isAbove(error.message.search('exceeds gas'), -1, 'Exceeds gas limit must be returned');
}
