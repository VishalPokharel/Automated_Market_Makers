// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IERC20.sol";

contract CPAMM
{


    IERC20 public immutable token0; // let token0 and token1 be two tokens in the pool
    IERC20 public immutable token1;

    uint256 public reserve0; //total token0 in pool
    uint256 public reserve1; //total token1 in pool 

    uint256 public totalSupply; //total shares in pool 
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


    //swap

    function swap(address _tokenIn, uint _amountIn) external returns(uint amountOut)
    {
        require( _tokenIn == address(token0) || _tokenIn == address(token1),
        "invalid token"
        );
        require( _amountIn>0,"not enough amount");

        //pull in token in 
        bool isToken0 = _tokenIn == address(token0);

        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) =
         isToken0 ? 
        (token0,token1,reserve0,reserve1):(token1,token0,reserve1,reserve0);

        tokenIn.transferFrom(msg.sender,address(this),_amountIn);

        //calculate token out 
        // ydx/(x+dx) =dy
        uint amountInWithFee= (_amountIn *997)/1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);



        //transfer token out
        tokenOut.transfer(msg.sender, amountOut);

        //update reserves
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));

    }

    //addliquidity
    function addLiquidity(uint _amount0, uint _amount1) external returns(uint shares)
    {
        token0.transferFrom(msg.sender,address(this), _amount0);
        token1.transferFrom(msg.sender,address(this), _amount1);

        if(reserve0 >0 || reserve1>0)
        {
            //dy/dx= y/x
            require((reserve0 * _amount1) == (reserve1*_amount0),"maths error hehe");
        }    

        // f(x,y) =value of liquidity = sqrt(xy)
        //s=dx/x*T=dy/y*T
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );
        }

        require(shares > 0, "shares = 0");
        _mintshares(msg.sender, shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));


    }


function removeLiquidity(uint _shares)
        external
        returns (uint amount0, uint amount1)
    {
        /*
        Claim
        dx, dy = amount of liquidity to remove
        dx = s / T * x
        dy = s / T * y

        Proof
        Let's find dx, dy such that
        v / L = s / T
        
        where
        v = f(dx, dy) = sqrt(dxdy)
        L = total liquidity = sqrt(xy)
        s = shares
        T = total supply

        --- Equation 1 ---
        v = s / T * L
        sqrt(dxdy) = s / T * sqrt(xy)

        Amount of liquidity to remove must not change price so 
        dx / dy = x / y

        replace dy = dx * y / x
        sqrt(dxdy) = sqrt(dx * dx * y / x) = dx * sqrt(y / x)

        Divide both sides of Equation 1 with sqrt(y / x)
        dx = s / T * sqrt(xy) / sqrt(y / x)
           = s / T * sqrt(x^2) = s / T * x

        Likewise
        dy = s / T * y
        */

        // bal0 >= reserve0
        // bal1 >= reserve1
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        _burnshares(msg.sender, _shares);
        _update(bal0 - amount0, bal1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }


    function _sqrt(uint y) private pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }

    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

}