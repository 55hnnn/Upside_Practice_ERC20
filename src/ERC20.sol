// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ERC20 {
    address owner;
    bool ispause;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private _totalSupply;

    string private name;
    string private symbol;
    uint8 private decimal;

    mapping(address => uint256) private _nonces;

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _from, address _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        owner = msg.sender;
        ispause = false;

        _mint(owner, 100 ether);
    }

    modifier ispaused() {
        require(ispause == false, "contract is paused");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;        
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external ispaused() returns (bool){
        require(msg.sender != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(balances[msg.sender] >= _value, "value exceeds balance");

        unchecked {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
        }// 오버플로우 검사x
        
        emit Transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) external ispaused() returns (bool) {
        require(msg.sender != address(0), "transfer from the zero address");
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");

        uint256 currentAllowance = allowance(_from, msg.sender);
        require(currentAllowance >= _value, "insufficient allowance");
        unchecked {
            allowances[_from][msg.sender] -= _value;
        }
        require(balances[_from] >= _value, "value exceeds balance");

        unchecked {
            balances[_from] -= _value;
            balances[_to] += _value;
        }

        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool){
        require(msg.sender != address(0), "approve from the zero address");
        require(_spender != address(0), "approve to the zero address");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowances[_owner][_spender];
    }

    function _mint(address _owner, uint256 _value) internal {
        require(_owner != address(0), "mint to the zero address");
        _totalSupply += _value;
        unchecked {
            balances[_owner] += _value;
        }
        emit Transfer(address(0), _owner, _value);
    }

    function pause() external {
        require(msg.sender == owner, "only owner");
        ispause = !ispause;
    }

    // EIP-2612 Permit Implementation
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function permit(address _owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            _owner,
            spender,
            value,
            _nonces[_owner],
            deadline
        ));

        bytes32 hash = _toTypedDataHash(structHash);
        address signer = ecrecover(hash, v, r, s);
        require(signer == _owner, "INVALID_SIGNER");

        _nonces[_owner] += 1;
        _approve(_owner, spender, value);
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")), // Version
                block.chainid,
                address(this)
            )),
            structHash
        ));
    }

    function nonces(address _owner) external view returns (uint256){
        return _nonces[_owner];
    }

    function _approve(address _owner, address spender, uint256 value) internal {
        allowances[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
}