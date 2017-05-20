pragma solidity ^0.4.11;

contract DynamicCeiling {

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

    function setHiddenPoints(bytes32[] _pointHashes) {
        if (msg.sender != creator) throw;
        if (points.length > 0) throw;
        uint i;
        points.length = _pointHashes.length;
        for (i=0; i< _pointHashes.length; i++) {
            points[i].hash = _pointHashes[i];
        }
    }


    function revealPoint(uint _block, uint _limit, bool _last, uint _salt) {
        if (allRevealed) throw;
        if (points[revealedPoints].hash != sha3(_block, _limit, _last, _salt)) throw;
        if (revealedPoints > 0) {
            if (_block <= points[revealedPoints - 1].block) throw;
            if (_limit < points[revealedPoints - 1].limit) throw;
        }
        points[revealedPoints].block = _block;
        points[revealedPoints].limit = _limit;
        points[revealedPoints].revealed = true;
        revealedPoints ++;
        if (_last) allRevealed = true;
    }

    function cap(uint _block) constant returns (uint) {
        if (revealedPoints == 0) return 0;

        // Shortcut for the actual value
        if (_block >= points[revealedPoints-1].block)
            return points[revealedPoints-1].limit;
        if (_block < points[0].block) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = revealedPoints-1;
        while (max != min + 1) {
            uint mid = (max + min)/ 2;
            if (points[mid].block<=_block) {
                min = mid;
            } else {
                max = mid;
            }
        }

        return points[min].limit  +
            (_block - points[min].block) *
                ( points[max].limit - points[min].limit ) /
                ( points[max].block - points[min].block );
    }

    function calculateHash(uint _block, uint _limit, bool _last, uint _salt) constant returns (bytes32) {
        return sha3(_block, _limit, _last, _salt);
    }

    function nPoints() constant returns(uint) {
        return points.length;
    }
}
