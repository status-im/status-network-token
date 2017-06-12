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


contract DynamicCeiling {
    using SafeMath for uint256;

    struct Curve {
        bytes32 hash;
        uint256 limit;
    }

    uint256 constant public slopeFactor = 30;
    uint256 constant public collectMinimum = 10**15;

    address public creator;
    uint256 public currentIndex;
    uint256 public revealedCurves;
    bool public allRevealed;
    Curve[] public curves;

    function DynamicCeiling() {
        creator = msg.sender;
    }

    /// @notice This should be called by the creator of the contract to commit
    ///  all the curves.
    /// @param _curveHashes Array of hashes of each curve. Each hash is calculated
    ///  by the `calculateHash` method. More hashes than actual curves can be
    ///  committed in order to hide also the number of curves.
    ///  The remaining hashes can be just random numbers.
    function setHiddenCurves(bytes32[] _curveHashes) public {
        if (msg.sender != creator) throw;
        if (curves.length > 0) throw;

        curves.length = _curveHashes.length;
        for (uint256 i = 0; i < _curveHashes.length; i = i.add(1)) {
            curves[i].hash = _curveHashes[i];
        }
    }


    /// @notice Anybody can reveal the next curve if he knows it.
    /// @param _limit Ceiling cap.
    ///  (must be greater or equal to the previous one).
    /// @param _last `true` if it's the last curve.
    /// @param _salt Random number used to commit the curve
    function revealCurve(uint256 _limit, bool _last, bytes32 _salt) public {
        if (allRevealed) throw;

        if (curves[revealedCurves].hash != keccak256(_limit, _last, _salt)) throw;

        if (revealedCurves > 0) {
            if (_limit < curves[revealedCurves.sub(1)].limit) throw;
        }

        curves[revealedCurves].limit = _limit;
        revealedCurves = revealedCurves.add(1);

        if (_last) allRevealed = true;
    }

    /// @return Return the funds to collect for the current curve on the limit curve
    ///  (or 0 if no curves revealed yet)
    function toCollect(uint256 collected) public returns (uint256) {
        if (revealedCurves == 0) return 0;

        // Move to the next curve
        if (collected >= curves[currentIndex].limit) {  // Catches `limit == 0`
            uint256 nextIndex = currentIndex.add(1);
            if (nextIndex == revealedCurves) return 0;  // No more curves
            currentIndex = nextIndex;
            if (collected >= curves[currentIndex].limit) return 0;  // Catches `limit == 0`
        }

        // Everything left to collect from this limit
        uint256 difference = curves[currentIndex].limit.sub(collected);

        // Current curve on curve
        uint256 collect = difference.div(slopeFactor);

        // Prevents paying too much fees vs to be collected; breaks long tail
        if (collect <= collectMinimum) {
            return difference;
        } else {
            return collect;
        }
    }

    /// @notice Calculates the hash of a curve.
    /// @param _limit Ceiling cap.
    /// @param _last `true` if it's the last curve.
    /// @param _salt Random number that will be needed to reveal this curve.
    /// @return The calculated hash of this curve to be used in the `setHiddenCurves` method
    function calculateHash(uint256 _limit, bool _last, bytes32 _salt) public constant returns (bytes32) {
        return keccak256(_limit, _last, _salt);
    }

    /// @return Return the total number of curves committed
    ///  (can be larger than the number of actual curves on the curve to hide
    ///  the real number of curves)
    function nCurves() public constant returns (uint256) {
        return curves.length;
    }

}
