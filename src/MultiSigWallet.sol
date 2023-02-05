// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 indexed amount);
    event SubmitTransaction(uint256 indexed txId);
    event ApproveTransaction(address indexed owner, uint256 indexed txId);
    event RevokeTransaction(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(uint256 indexed txId);

    // Represents a transaction that is submitted for approval
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    // number of approvals we need to approve a transaction
    uint256 public immutable numApprovalsRequired;

    Transaction[] public transactions;
    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isApproved;

    // MODIFIERS

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!isApproved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    /// @notice Inizialize the contract with owners and number of approvals required for a transaction to be approved
    constructor(address[] memory _owners, uint256 _numApprovalsRequired)
        payable
    {
        require(_owners.length > 0, "Owners required");
        require(
            _numApprovalsRequired > 0 &&
                _numApprovalsRequired <= _owners.length,
            "Invalid required number of owners"
        );

        for (uint256 i; i < _owners.length; ++i) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numApprovalsRequired = _numApprovalsRequired;
    }

    /// @notice Used to receive ether from an EOA or contract.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Used to submit a transaction for approval by owners
    /// @param _to Address of the receiver
    /// @param _value Amount of ether to send to the receiver
    /// @param _data Any additional data needed to be sent
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        require(_to != address(0), "invalid input: zero addr");
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit SubmitTransaction(transactions.length - 1);
    }

    /// @notice Used to approve a pending transaction
    /// @param _txId ID of the transaction waiting for approval
    function approveTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        isApproved[_txId][msg.sender] = true;
        emit ApproveTransaction(msg.sender, _txId);
    }

    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        uint256 ownersLength = owners.length;
        for (uint256 i; i < ownersLength; ++i) {
            if (isApproved[_txId][owners[i]]) {
                ++count;
            }
        }
    }

    function executeTransaction(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        require(
            _getApprovalCount(_txId) >= numApprovalsRequired,
            "Transaction not yet approved by enough owners"
        );
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(_txId);
    }

    function revokeApproval(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isApproved[_txId][msg.sender], "tx not approved");
        isApproved[_txId][msg.sender] = false;
        emit RevokeTransaction(msg.sender, _txId);
    }

    function getTransaction(uint256 _txId)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed
        )
    {
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed
        );
    }
}
