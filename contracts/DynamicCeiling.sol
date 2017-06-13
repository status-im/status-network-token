pragma solidity ^0.4.11;

import "./Owned.sol";

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
/// @dev This contract calculates the ceiling from a series of points.
///  These points are committed first and revealed later.
///  All the points must be in increasing order and the last point is marked
///  as the last one.
///  This contract allows to hide and reveal the ceiling at will of the owner.


import "./SafeMath.sol";


contract DynamicCeiling is Owned {
    using SafeMath for uint256;

    struct CurvePoint {
        bytes32 hash;
        uint256 block;
        uint256 limit;
    }

    uint256 public revealedPoints;
    bool public allRevealed;
    CurvePoint[] public points;

    function DynamicCeiling() {
    }

    /// @notice This should be called by the creator of the contract to commit
    ///  all the points of the curve.
    /// @param _pointHashes Array of hashes of each point. Each hash is calculated
    ///  by the `calculateHash` method. More hashes than actual points of the curve
    ///  can be committed in order to hide also the number of points of the curve.
    ///  The remaining hashes can be just random numbers.
    function setHiddenPoints(bytes32[] _pointHashes) onlyOwner public {
        if (points.length > 0) throw;

        points.length = _pointHashes.length;
        for (uint256 i = 0; i < _pointHashes.length; i = i.add(1)) {
            points[i].hash = _pointHashes[i];
        }
    }


    /// @notice Anybody can reveal the next point of the curve if he knows it.
    /// @param _limit Ceiling cap at that block.
    ///  (must be greater or equal than the previous one).
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number used to commit the point
    function revealPoint(uint256 _block, uint256 _limit, bool _last, bytes32 _salt) onlyOwner public {
        if (allRevealed) throw;
        if (points[revealedPoints].hash != sha3(_limit, _last, _salt)) throw;
        if (revealedPoints > 0) {
            if (_block <= points[revealedPoints.sub(1)].block) throw;
            if (_limit < points[revealedPoints.sub(1)].limit) throw;
        }
        points[revealedPoints].block = _block;
        points[revealedPoints].limit = _limit;
        revealedPoints = revealedPoints.add(1);
        if (_last) allRevealed = true;
    }

    /// @return Return the limit at specific block number
    ///  (or 0 if no points revealed yet or block before first point)
    function cap(uint256 _block) public constant returns (uint256 _cap) {
        if (revealedPoints == 0) return 0;

        // Shortcut if _block is after most recently revealed point
        if (_block >= points[revealedPoints.sub(1)].block)
            return points[revealedPoints.sub(1)].limit;
        if (_block < points[0].block) return 0;

        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = revealedPoints.sub(1);
        while (max != min.add(1)) {
            uint256 mid = max.add(min).div(2);
            if (points[mid].block<=_block) {
                min = mid;
            } else {
                max = mid;
            }
        }

        return points[min].limit.add(
            _block.sub(points[min].block).mul(
                points[max].limit.sub(points[min].limit)).div(
                    points[max].block.sub(points[min].block)));
    }

    /// @notice Calculates the hash of a point.
    /// @param _limit Ceiling cap at that block.
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number that will be needed to reveal this point.
    /// @return The calculated hash of this point to be used in the
    ///  `setHiddenPoints` method
    function calculateHash(uint256 _limit, bool _last, bytes32 _salt) public constant returns (bytes32) {
        return sha3(_limit, _last, _salt);
    }

    /// @return Return the total number of points committed
    ///  (can be larger than the number of actual points on the curve to hide
    ///  the real number of points)
    function nPoints() public constant returns(uint256) {
        return points.length;
    }

}
