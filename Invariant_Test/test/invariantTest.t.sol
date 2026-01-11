// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {InvariantContract} from "../src/invariantContract.sol";

contract InvariantTest is Test {
     InvariantContract foo;
 
    function setUp() external {
        foo = new InvariantContract();
        targetContract(address(foo));
    }
 
    function invariant_A() external view {
        assertEq(foo.val1() + foo.val2(), foo.val3());
    }
 
    function invariant_B() external view {
        assertGe(foo.val1() + foo.val2(), foo.val3());
    }
}
