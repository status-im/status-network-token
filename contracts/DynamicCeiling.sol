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
/// @dev This contract calculates the A cailing from a series of points.
///  This points are commited firs and revealed later.
///  All the points must be in increasing order and the last point is marked
///  as the last one.
///  This contract allows to hide and reveal the ceiling at will of the owner.


import "./SafeMath.sol";

contract DynamicCeiling is SafeMath {

    struct CurvePoint {
        bytes32 hash;
        uint block;
        uint limit;
        bool revealed;
    }

    address creator;
    uint public revealedPoints;
    bool public allRevealed;
    CurvePoint[] public points;

    function DynamicCeiling() {
        creator = msg.sender;
    }

    /// @notice This should be called by the creator of the contract to commit
    ///  all the points of the curve.
    /// @param _pointHashes Array of hashes of each point. Each hash is callculated
    ///  by the `calculateHash` method. More hashes that the actual points of the curve
    ///  can be commited in order to hide also the number of points of the curve.
    ///  The remaining hashes can be just random numbers.
    function setHiddenPoints(bytes32[] _pointHashes) {
        if (msg.sender != creator) throw;
        if (points.length > 0) throw;
        uint i;
        points.length = _pointHashes.length;
        for (i=0; i< _pointHashes.length; i = safeAdd(i,1)) {
            points[i].hash = _pointHashes[i];
        }
    }


    /// @notice Any body can revel the next point of the curve if he knows it.
    /// @param _block Block number where this point of the curve is defined.
    ///  (Must be greater than the previous one)
    /// @param _limit Ceiling cat at that block.
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number used to commit the point
    function revealPoint(uint _block, uint _limit, bool _last, bytes32 _salt) {
        if (allRevealed) throw;
        if (points[revealedPoints].hash != sha3(_block, _limit, _last, _salt)) throw;
        if (revealedPoints > 0) {
            if (_block <= points[safeSub(revealedPoints, 1)].block) throw;
            if (_limit < points[safeSub(revealedPoints, 1)].limit) throw;
        }
        points[revealedPoints].block = _block;
        points[revealedPoints].limit = _limit;
        points[revealedPoints].revealed = true;
        revealedPoints = safeAdd(revealedPoints, 1);
        if (_last) allRevealed = true;
    }

    /// @return Return the limit at specific block number
    function cap(uint _block) constant returns (uint) {
        if (revealedPoints == 0) return 0;

        // Shortcut for the actual value
        if (_block >= points[safeSub(revealedPoints,1)].block)
            return points[safeSub(revealedPoints,1)].limit;
        if (_block < points[0].block) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = safeSub(revealedPoints,1);
        while (max != safeAdd(min, 1)) {
            uint mid = safeDiv(safeAdd(max, min), 2);
            if (points[mid].block<=_block) {
                min = mid;
            } else {
                max = mid;
            }
        }

        return safeAdd(
                    points[min].limit,
                    safeDiv(
                        safeMul(
                            safeSub(_block, points[min].block),
                            safeSub(points[max].limit, points[min].limit)),
                        safeSub(points[max].block, points[min].block)));

    }

    /// @notice Calculates the hash of a point.
    /// @param _block Block number where this point of the curve is defined.
    ///  (Must be greater than the previous one)
    /// @param _limit Ceiling cat at that block.
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number that will be needed to reveal this point.
    /// @return The calculated hash of this point to be used in the
    ///  `setHiddenPoints` method
    function calculateHash(uint _block, uint _limit, bool _last, bytes32 _salt) constant returns (bytes32) {
        return sha3(_block, _limit, _last, _salt);
    }

    /// @return Return the total number of points commited
    function nPoints() constant returns(uint) {
        return points.length;
    }
}
