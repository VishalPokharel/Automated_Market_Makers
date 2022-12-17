// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IERC20.sol";


contract CSAMM{ // constant sum automated market maker 

    IERC20 public immutable token0; // let token0 and token1 be two tokens in the pool
    IERC20 public immutable token1;

    uint256 public reserve0; //total token0 in pool
    uint256 public reserve1; //total token1 in pool 

    uint256 public totalSupply; //total tokens in pool 
    mapping(address => uint) public balanceOf; // total shares of a user.

/* here the address means the address of the erc20 tokens deployed .
 erc20.sol is deployed two times two get two different address of the tokens.
 and the given two tokens are thus assigned to deployed tokens.*/

    constructor(address _token0, address _token1) { 
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

    }

    function _update(uint _res0, uint _res1) private{
        reserve0 = _res0;
        reserve1 = _res1;
    }

    function _mintshares(address _to, uint256 _amount) private{
        balanceOf[_to] += _amount;
        totalSupply += totalSupply;
    }

    function _burnshares(address _from, uint256 _amount) private{
    balanceOf[_from] -= _amount;
    totalSupply -= totalSupply;
    }



    function swap(address _tokenIn, uint256 _amountIn) external returns(uint amountOut){
        require(_tokenIn == address(token0) || _tokenIn == address(token1),"invalid address" );

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isToken0 
        ?(token0,token1, reserve0, reserve1)
        :(token1,token0,reserve1,reserve0);


        //transfer tokenIn

        tokenIn.transferFrom(msg.sender,address(this), _amountIn);
        uint amountIn = tokenIn.balanceOf(address(this))-resIn;

        //calculate amountOut including fees of 0.3% ok .

        amountOut = (amountIn*997)/1000;

        //update reserves.
        (uint res0, uint res1) = isToken0
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);
        _update(res0, res1);
        //transfer token out.
        tokenOut.transfer(msg.sender, amountOut);

    }


    function addLiquidity(uint _amount0, uint _amount1) external returns(uint shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        uint d0 = bal0 - reserve0;
        uint d1 = bal1 - reserve1;

        //s=at/l

        if(totalSupply == 0){
            shares = d0+d1;
        }
        else{
            shares = ((d0+d1)*totalSupply)/(reserve1+reserve0);
        }

        require(shares>0,"shares = 0");
        _mintshares(msg.sender,shares);
        _update(bal0,bal1);

    }



    function removeLiquidity(uint shares) external returns(uint d0,uint d1){
        d0=(reserve0*shares)/totalSupply;
        d1=(reserve1*shares)/totalSupply;

        _burnshares(msg.sender, shares);
        _update(reserve0-d0, reserve1-d1);

        if(d0>0){
            token0.transfer(msg.sender, d0);
        }
        if(d0>0){
            token1.transfer(msg.sender, d1);
        }

    }

}
