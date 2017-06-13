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
/// @dev This contract calculates the ceiling from a series of points.
///  These points are committed first and revealed later.
///  All the points must be in increasing order and the last point is marked
///  as the last one.
///  This contract allows to hide and reveal the ceiling at will of the owner.


import "./SafeMath.sol";
import "./Owned.sol";


contract DynamicCeiling is Owned {
    using SafeMath for uint256;

    struct Point {
        bytes32 hash;
        uint256 limit;
    }

    // The funds remaining to be collected are divided by `slopeFactor` smooth ceiling
    // with a long tail where big and small buyers can take part.
    uint256 constant public slopeFactor = 30;
    // This keeps the curve flat at this number, until funds to be collected is less than this
    uint256 constant public collectMinimum = 10**15;

    uint256 constant public initialSlopeFactor = 300;
    uint256 constant public finalSlopeFactor = 30;
    uint256 constant public blocksToFinalSlope = 240;

    address public contribution;

    Point[] public points;
    uint256 public currentIndex;
    uint256 public revealedPoints;
    bool public allRevealed;

    uint256 public initialBlock;

    /// @dev `contribution` is the only address that can call a function with this
    /// modifier
    modifier onlyContribution {
        if (msg.sender != contribution) throw;
        _;
    }

    function DynamicCeiling(address _owner, address _contribution) {
        owner = _owner;
        contribution = _contribution;
    }

    /// @notice This should be called by the creator of the contract to commit
    ///  all the points of the curve.
    /// @param _pointHashes Array of hashes of each point. Each hash is calculated
    ///  by the `calculateHash` method. More hashes than actual points of the curve
    ///  can be committed in order to hide also the number of points of the curve.
    ///  The remaining hashes can be just random numbers.
    function setHiddenPoints(bytes32[] _pointHashes) public onlyOwner {
        if (points.length > 0) throw;

        points.length = _pointHashes.length;
        for (uint256 i = 0; i < _pointHashes.length; i = i.add(1)) {
            points[i].hash = _pointHashes[i];
        }
    }


    /// @notice Anybody can reveal the next point of the curve if he knows it.
    /// @param _limit Ceiling cap.
    ///  (must be greater or equal to the previous one).
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number used to commit the point
    function revealPoint(uint256 _limit, bool _last, bytes32 _salt) public {
        if (allRevealed) throw;

        if (points[revealedPoints].hash != keccak256(_limit, _last, _salt)) throw;

        if (revealedPoints > 0) {
            if (_limit < points[revealedPoints.sub(1)].limit) throw;
        }

        points[revealedPoints].limit = _limit;
        revealedPoints = revealedPoints.add(1);

        if (_last) allRevealed = true;
    }

    /// @notice Move to point, used as a failsafe
    function moveTo(uint256 _index) public onlyOwner {
        if (_index >= revealedPoints ||            // No more points
            _index != currentIndex.add(1)) throw;  // Only move one index at a time
        currentIndex = _index;
    }

    /// @return Return the funds to collect for the current point on the point
    ///  (or 0 if no points revealed yet)
    function toCollect(uint256 collected) public onlyContribution returns (uint256) {

        uint256 slopeFactor;
        uint256 blocksFromInit = (getBlockNumber() - initialBlock);
        if (blocksFromInit >= blocksToFinalSlope) {
            slopeFactor = finalSlopeFactor;
        } else {

            uint256 a = (initialSlopeFactor.sub(finalSlopeFactor)).div(blocksToFinalSlope);

            slopeFactor = initialSlopeFactor.sub(a.mul(blocksFromInit));
        }

        if (revealedPoints == 0) return 0;

        // Move to the next point
        if (collected >= points[currentIndex].limit) {  // Catches `limit == 0`
            uint256 nextIndex = currentIndex.add(1);
            if (nextIndex >= revealedPoints) return 0;  // No more points
            currentIndex = nextIndex;
            if (collected >= points[currentIndex].limit) return 0;  // Catches `limit == 0`
        }

        // Everything left to collect from this limit
        uint256 difference = points[currentIndex].limit.sub(collected);

        // Current point on the point
        uint256 collect = difference.div(slopeFactor);

        // Prevents paying too much fees vs to be collected; breaks long tail
        if (collect <= collectMinimum) {
            if (difference > collectMinimum) {
                return collectMinimum;
            } else {
                return difference;
            }
        } else {
            return collect;
        }
    }

    /// @notice Calculates the hash of a point.
    /// @param _limit Ceiling cap.
    /// @param _last `true` if it's the last point of the curve.
    /// @param _salt Random number that will be needed to reveal this point.
    /// @return The calculated hash of this point to be used in the `setHiddenPoints` method
    function calculateHash(uint256 _limit, bool _last, bytes32 _salt) public constant returns (bytes32) {
        return keccak256(_limit, _last, _salt);
    }

    /// @return Return the total number of points committed
    ///  (can be larger than the number of actual points on the curve to hide
    ///  the real number of points)
    function nPoints() public constant returns (uint256) {
        return points.length;
    }

    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

}
