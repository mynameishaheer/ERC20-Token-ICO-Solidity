//REFERENCES
//https://youtu.be/gwn1rVDuGL0?list=PLO5VPQH6OWdVfvNOaEhBtA53XHyHo_oJo - didnt work
//https://www.quicknode.com/guides/solidity/how-to-create-and-deploy-an-erc20-token - didnt work

//https://www.youtube.com/watch?v=GDq7r1n9zIU - for working ERC20 Token
//https://gist.github.com/raghu-19/e500786eba2b60034573843ef88fda89 - for working ICO

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    //returns the total amount of this token available
    function totalSupply() external view returns (uint256);

    //returns the amount of this token that the specific count has
    function balanceOf(address account) external view returns (uint256 balance);

    //holder of the token can call this function to transfer token directly
    function transfer(address to, uint256 amount)
        external
        returns (bool success);

    //allows holder of this token to approve someone else to spend his token
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    //specifies how much a spender can spend from a holder
    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    //holder of the token calls approve to allow spender to spend his money
    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    //ERC20 standards
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b >= a);
        c = a / b;
    }
}

contract SheerToken is IERC20, SafeMath {
    address payable owner;

    //token metadata - decimals = 18 (10^18) - default
    string public name;
    string public symbol;
    uint8 public decimals;

    //store total supply of this token
    uint256 public _totalSupply;

    //keep track of all user balances
    mapping(address => uint256) public balances;

    //keep track of which user is allowed to spend how much of another user's token
    //can only spend if approved by the tokenOwner
    //tokenOwner -> spender -> amount
    mapping(address => mapping(address => uint256)) allowed;

    //init token details
    constructor() {
        name = "SheerToken";
        symbol = "SHT";
        decimals = 18;

        //1 billion tokens (remove the last 18 zeros)
        _totalSupply = 100000000000000000000000000;

        owner = payable(msg.sender);

        //all initial supply given to the creator of the token
        balances[owner] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //returns total supply of the token
    function totalSupply() external view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    //returns balance of the given account address
    function balanceOf(address account)
        external
        view
        override
        returns (uint256 balance)
    {
        return balances[account];
    }

    //return allowed amount of tokens for a specified spender of a token of a token owner
    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    //allowed to approve a spender to spend the tokenOwner's token
    //called by the tokenOwner
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //function called by the tokenOwner to transfer his owned token
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool success)
    {
        balances[msg.sender] = sub(balances[msg.sender], amount);
        balances[to] = add(balances[to], amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    //function to transfer another tokenOwner's tokens on his behalf
    //this function is called by the spender
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool success) {
        //will only subtract if the spender is listed under the tokenOwner's allowance key
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], amount);

        balances[from] = sub(balances[from], amount);
        balances[to] = add(balances[to], amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /* FIXED
    //Due to some error the contract was not initializing and transferring
    //the total supply to the creators account
    //the mint functions allows a user to pay the contract in ether
    //it then gives the same amount in SHT back to the payer
    function mint() external payable returns (bool success) {
        require(_totalSupply > 0);
        balances[msg.sender] += msg.value;
        _totalSupply -= msg.value;
        return true;
    }
    //allows an owner to withdraw the amount of ether sent in exchange for a token
    function withdrawOwner() external {
        require(msg.sender == owner, "You dont have rights");
        owner.transfer(address(this).balance);
    } */ 
}

//for some reason this is not working properly
//it is transferring the ether to the owner
//but it is not giving the token to the investor
//nor is it reducing the tokens from the owner
contract SheerTokenICO is SheerToken {
    address payable public admin;

    uint256 public tokenPrice = 0.001 ether;
    uint256 public hardCap = 500 ether;

    uint256 public amountRaised;

    uint256 public start = block.timestamp;
    uint256 public end = block.timestamp + 604800;

    uint256 public tradeStart = end + 604800;

    uint256 public maxInvest = 5 ether;
    uint256 public minInvest = 0.01 ether;

    enum State {
        beforeStart,
        Ongoing,
        afterEnd,
        Paused
    }
    State public icoState;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event Invest(address investor, uint256 value, uint256 amount);

    constructor() {
        admin = payable(msg.sender);
        icoState = State.beforeStart;
    }

    //function to allow pausing of ICO
    function pause() public onlyAdmin {
        icoState = State.Paused;
    }
    //function to allow unpausing of ICO
    function unpause() public onlyAdmin {
        icoState = State.Ongoing;
    }

    //function to return the current state of the ICO
    //checks the blocktimestamp and returns the state
    function getState() public view returns (State currentState) {
        if (icoState == State.Paused) {
            return State.Paused;
        } else if (block.timestamp < start) {
            return State.beforeStart;
        } else if (block.timestamp >= start && block.timestamp <= end) {
            return State.Ongoing;
        } else {
            return State.afterEnd;
        }
    }

    //primary function used to invest in the Token
    //not working properly
    //ensures state is running and the amount invested is in between the limits
    //calcuates the tokens that should be sent to the investor
    //sends ether to admin account
    //should send token to investor account but is not doing so atm
    function invest() payable external returns (bool success){
        require(getState() == State.Ongoing);
        require(msg.value >= minInvest && msg.value <= maxInvest);
        uint tokenToTransfer = msg.value/tokenPrice;
        require(amountRaised + msg.value <= hardCap);
        amountRaised = amountRaised + msg.value;

        balances[msg.sender] += tokenToTransfer;
        balances[owner] -= tokenToTransfer;

        admin.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokenToTransfer);
        
        return true;
    }

    //post ICO function transfer
    //similar to parent function except with timestamp check
    function transfer(address to, uint amount) override public returns (bool success){
        require(block.timestamp > tradeStart);
        return super.transfer(to, amount);
    }

    //post ICO function transferFrom
    //similar to parent function except with timestamp check
    function transferFrom(address from, address to, uint amount) override public returns(bool success){
        require(block.timestamp > tradeStart);
        return super.transferFrom(from, to, amount);
    }

    //post ICO function allows the admin to burn all the initial coins 
    //in order to work with the coins that are already in the market
    //plus mine new coins to maintian the network
    function burn() external onlyAdmin returns (bool success) {
        require(getState() == State.afterEnd);
        balances[owner] = 0;
        return true;
    }
}
