pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title DynamicCeiling Contract
/// @author Jordi Baylina
/// @dev This contract calculates the ceiling from a series of curves.
///  These curves are committed first and revealed later.
///  All the curves must be in increasing order and the last curve is marked
///  as the last one.
///  This contract allows to hide and reveal the ceiling at will of the owner.


import "./SafeMath.sol";
import "./Owned.sol";

contract DynamicCeiling is Owned {
    using SafeMath for uint256;

    struct Curve {
        uint256 block;
        bytes32 hash;
        // Absolute limit for this curve
        uint256 limit;
        // The funds remaining to be collected are divided by `slopeFactor` smooth ceiling
        // with a long tail where big and small buyers can take part.
        uint256 slopeFactor;
        // This keeps the curve flat at this number, until funds to be collected is less than this
        uint256 collectMinimum;
    }

    address public contribution;

    Curve[] public curves;
    uint256 public revealedCurves;
    bool public allRevealed;

    /// @dev `contribution` is the only address that can call a function with this
    /// modifier
    modifier onlyContribution {
        require(msg.sender == contribution);
        _;
    }

    function DynamicCeiling(address _owner) {
        owner = _owner;
    }

    /// @notice This should be called by the creator of the contract to commit
    ///  all the curves.
    /// @param _curveHashes Array of hashes of each curve. Each hash is calculated
    ///  by the `calculateHash` method. More hashes than actual curves can be
    ///  committed in order to hide also the number of curves.
    ///  The remaining hashes can be just random numbers.
    function setHiddenCurves(bytes32[] _curveHashes) public onlyOwner {
        require(curves.length == 0);

        curves.length = _curveHashes.length;
        for (uint256 i = 0; i < _curveHashes.length; i = i.add(1)) {
            curves[i].hash = _curveHashes[i];
        }
    }


    /// @notice Anybody can reveal the next curve if he knows it.
    /// @param _block The block when starts to take effect this curve.
    /// @param _limit Ceiling cap.
    ///  (must be greater or equal to the previous one).
    /// @param _last `true` if it's the last curve.
    /// @param _salt Random number used to commit the curve
    function revealCurve(uint256 _block, uint256 _limit, uint256 _slopeFactor, uint256 _collectMinimum,
                         bool _last, bytes32 _salt) public {
        require(!allRevealed);

        require(curves[revealedCurves].hash == keccak256(_limit, _slopeFactor, _collectMinimum,
                                                     _last, _salt));

        require(_limit != 0 && _slopeFactor != 0 && _collectMinimum != 0);
        if (revealedCurves > 0) {
            require(_limit >= curves[revealedCurves.sub(1)].limit);
            require(_block > curves[revealedCurves.sub(1)].block);
        }

        curves[revealedCurves].block = _block;
        curves[revealedCurves].limit = _limit;
        curves[revealedCurves].slopeFactor = _slopeFactor;
        curves[revealedCurves].collectMinimum = _collectMinimum;
        revealedCurves = revealedCurves.add(1);

        if (_last) allRevealed = true;
    }

    /// @notice Reveal multiple curves at once
    function revealMulti(uint256[] _blocks, uint256[] _limits, uint256[] _slopeFactors, uint256[] _collectMinimums,
                        bool[] _lasts, bytes32[] _salts) public {
        // Do not allow none and needs to be same length for all parameters
        require(_limits.length != 0 &&
                _limits.length == _slopeFactors.length &&
                _limits.length == _collectMinimums.length &&
                _limits.length == _lasts.length &&
                _limits.length == _salts.length &&
                _limits.length == _blocks.length);

        for (uint256 i = 0; i < _limits.length; i = i.add(1)) {
            revealCurve(_blocks[i], _limits[i], _slopeFactors[i], _collectMinimums[i],
                        _lasts[i], _salts[i]);
        }
    }


    /// @notice delay all the points of the curves from a specific index,
    ///  a fixed number of blocks.
    ///  This migh be required if some body spam the chain in order to delay
    ///  the sell until the next block.
    function delayCurves(uint256 _curveIdx, uint256 _blocksDelay) onlyOwner {
        assert (_curveIdx < revealedCurves);
        require (curves[_curveIdx].block > block.number);
        for (uint i = _curveIdx; i<revealedCurves; i++) {
            curves[i].block = curves[i].block.add(_blocksDelay);
        }
    }

    /// @return Return the params of the curve at specific block
    ///  (or 0 if no points revealed yet or block before first point)
    function curve(uint256 _block) public constant returns (
        uint256 _currentIdx,
        uint256 _limit,
        uint256 _slopeFactor,
        uint256 _collectMinimum)  {
        if (revealedCurves == 0) return (0,0,0,0);
        if (_block < curves[0].block) return (0,0,0,0);

        _currentIdx = 0;
        while (  (_currentIdx<revealedCurves.sub(1))
               &&(curves[_currentIdx.add(1)].block <= _block)) {
            _currentIdx = _currentIdx.add(1);
        }

        _limit = curves[_currentIdx].limit;
        _slopeFactor = curves[_currentIdx].slopeFactor;
        _collectMinimum = curves[_currentIdx].collectMinimum;
    }

    /// @notice Calculates the hash of a curve.
    /// @param _limit Ceiling cap.
    /// @param _slopeFactor Slope Facotor.
    /// @param _collectMinimum Collect Minimum.
    /// @param _last `true` if it's the last curve.
    /// @param _salt Random number that will be needed to reveal this curve.
    /// @return The calculated hash of this curve to be used in the `setHiddenCurves` method
    function calculateHash(uint256 _limit, uint256 _slopeFactor, uint256 _collectMinimum,
                           bool _last, bytes32 _salt) public constant returns (bytes32) {
        return keccak256(_limit, _slopeFactor, _collectMinimum, _last, _salt);
    }

    /// @return Return the total number of curves committed
    ///  (can be larger than the number of actual curves on the curve to hide
    ///  the real number of curves)
    function nCurves() public constant returns (uint256) {
        return curves.length;
    }
}
