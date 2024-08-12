# Intro
`ERC20-1.t.sol` 파일과 `ERC20-2.t.sol` 파일에 구현된 테스트케이스를 통과하도록 `ERC20.sol`에 컨트랙트를 구현하자.

ERC20.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
	event Transfer(address _from, address _to, uint256 _value);
	event Approval(address _from, address _spender, uint256 _value);
	
	string private name;
	string private symbol;
	uint8 private decimal;
	
	function totalSupply() public view returns (uint256) {}
	function balanceOf(address _owner) public view returns (uint256){}
	function transfer(address _to, uint256 _value) external returns (bool){}
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {}
	function approve(address _spender, uint256 _value) external returns (bool){}
	function allowance(address _owner, address _spender) public view returns (uint256){}
}
```
# 함수 구현
## ERC20-1.t.sol
`ERC20-1.t.sol`에서는 기본적인 ERC20 요소와 토큰 전송을 멈추는 `pause()`함수의 구현을 요구한다.
### constructor()
```solidity
constructor(string memory _name, string memory _symbol) {
	name = _name;
	symbol = _symbol;
}
```
생성자는 이름과 심볼을 인자로 받아 이를 정의한다.
### totalSupply()
```solidity
uint256 private _totalSupply;
function totalSupply() public view returns (uint256) {
	return _totalSupply;
}
```
총 발행된 토큰의 양을 리턴하는 함수이다.
### balanceOf(owner)
```solidity
mapping(address => uint256) private balances;
function balanceOf(address _owner) public view returns (uint256){
	return balances[_owner];
}
```
`owner`의 잔액을 반환하는 함수이다.
### transfer(to, value)
```solidity
function transfer(address _to, uint256 _value) external returns (bool){
	require(msg.sender != address(0), "transfer from the zero address");
	require(_to != address(0), "transfer to the zero address");
	require(balances[msg.sender] >= _value, "value exceeds balance");
	  
	unchecked {
		balances[msg.sender] -= _value;
		balances[_to] += _value;
	}
	emit Transfer(msg.sender, _to, _value);
}
```
`to`에게 `value`만큼의 토큰을 전송하는 함수이다. 이때 `emit`을 통해 송금 이력을 나타내어 준다.
### approve(to, value)
```solidity
mapping(address => mapping(address => uint256)) private allowances;
function approve(address _spender, uint256 _value) external returns (bool){
	require(msg.sender != address(0), "approve from the zero address");
	require(_spender != address(0), "approve to the zero address");
	  
	allowances[msg.sender][_spender] = _value;
	  
	emit Approval(msg.sender, _spender, _value);
}
```
`to`에게 `value`만큼의 토큰 인출을 허용하는 함수이다. `tranferFrom` 함수는 다른 계정의 토큰을 인출하여 송금하는 동작을 수행하는데, 이때 허용된 토큰량만 인출할 수 있도록 제어하는 역할을 수행한다.
### allowance(owner, spender)
```solidity
function allowance(address _owner, address _spender) public view returns (uint256){
	return allowances[_owner][_spender];
}
```
`owner`가 `spender`에게 인출을 허용한 토큰량을 반환하는 함수이다.
### transferFrom(from, to, value)
```solidity
function transferFrom(address _from, address _to, uint256 _value) external  returns (bool) {
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
```
다른 계정의 토큰을 송금하는 함수이다 `allowances`에 정의된 토큰량만큼만 이용이 가능하다.
### mint()
```solidity
constructor(string memory _name, string memory _symbol) {
	...
	_mint(msg.sender, 100 ether);
}
function _mint(address _owner, uint256 _value) internal {
	require(_owner != address(0), "mint to the zero address");
	_totalSupply += _value;
	unchecked {
		balances[_owner] += _value;
	}
	emit Transfer(address(0), _owner, _value);
}
```
토큰을 발행하는 함수이다. 테스트케이스에서 테스트를 시작할 때 `setup()`에서 토큰 발행을 요구하므로, 생성자에서 `100 ether`만큼의 토큰을 발행한다.
### pause()
```solidity
address owner;
bool ispause;

constructor(string memory _name, string memory _symbol) {
	...
	owner = msg.sender;
	ispause = false;
}

modifier ispaused() {
	require(ispause == false, "contract is paused");
	_;
}

function pause() external {
	require(msg.sender == owner, "only owner");
	ispause = !ispause;
}

function transfer(address _to, uint256 _value) external ispaused() returns (bool){}
function transferFrom(address _from, address _to, uint256 _value) external ispaused() returns (bool) {}
```
토큰을 전송할 수 없도록 컨트랙트를 "일시정지"상태로 만들어 주는 함수이다.
이 컨트랙트의 `owner`와 일시정지 여부를 생성자에서 초기화하고, `pause()` 함수를 통해 컨트랙트를 제어한다. `transfer(to, value)`와 `transferFrom(from, to, value)`가 `pause()` 함수에 영향을 받도록 제어자를 선언하여 함수에 적용시킨다.
## ERC20-2.t.sol
`ERC20-1.2.sol`에서는 `permit()`에 대한 함수구현을 테스트한다.
### \_toTypedDataHash(structHash)
```solidity
function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
	return keccak256(abi.encodePacked(
		hex"1901",
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
```
EIP-712 표준에 따라 구조화된 데이터의 해시를 생성하기 위해서 사용되는 함수.
이더리움은 RLP 인코딩된 트랜잭션 데이터가 올바른 서명을 가질 경우, 이를 유효한 트랜잭션으로 인식한다. 이때, `0x19`값을 통해 RLP 인코딩이 아님을 명시하고, `0x01`로 구조화된 데이터를 사용함을 명시한다.
### nonces(owner)
```solidity
function nonces(address _owner) external view returns (uint256){
	return _nonces[_owner];
}
```
호출자의 `nonces` 값을 반환하는 함수
`permit`을 통한 서명이 리플레이 공격에 노출되지 않게 하기 위해 사용된다.
### permit(owner, spender, value, deadline, v, r, s)
```solidity
function permit(address _owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
	require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
	bytes32 structHash = keccak256(abi.encode(
		keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
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
	allowances[_owner][spender] = value;
}
```
`approve`없이 사용자 스스로 유효한 서명을 통해 `approve`를 수행할 수 있도록 하는 함수. EIP-2612에서 제안된대로 `structHash`가 유효하고, 서명값이 유효하면 해당 계정의 `allowances`를 증가시켜 준다.
# ERC20.sol
```solidity
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
		}
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
	  
	function permit(address _owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
		require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
		bytes32 structHash = keccak256(abi.encode(
			keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
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
		allowances[_owner][spender] = value;
	}
	  
	function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
		return keccak256(abi.encodePacked(
			hex"1901",
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
}
```
