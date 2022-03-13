pragma solidity ^0.4.2;

contract Recovery {
    address uuid;
    address[] contacts;
    mapping(address => address) recoveries;
    mapping(address => uint) proposed_keys;

    modifier onlyUuid(){
        if (msg.sender == uuid)
            _;
    }
    modifier onlyContact(){
        for(uint i = 0; i < contacts.length; i++)
            if(contacts[i] == msg.sender)
                _;
    }

    constructor(address _uuid) public{
        uuid = _uuid;
    }
    function setContacts(address[] _contacts) onlyUuid public {
        contacts = _contacts;
    }
    function getContacts() view public returns (address[] _contacts) {
        _contacts = contacts;
    }
    function addRecovery(address _key) onlyContact public {
        if(recoveries[msg.sender] != _key 
            && proposed_keys[recoveries[msg.sender]] == 0){
            recoveries[msg.sender] = _key;
            proposed_keys[_key] += 1;
        }
        if (proposed_keys[_key] >= (contacts.length / 2)){
            Identity identity_c = Identity(uuid);
            proposed_keys[_key] = 0;
            identity_c.transferOwner(_key);
        }
    }
    function getRecoveries(address _key) view public returns (uint num_done, uint num_total) {
        num_done = proposed_keys[_key];
        num_total = contacts.length / 2;
    }
}

contract Identity {
    address owner;
    string ipfs_hash;
    address recovery;

    modifier onlyOwner(){
        if (msg.sender == owner)
            _;
    }
    modifier onlyOwnerOrRecovery(){
        if (msg.sender == owner || msg.sender == recovery)
            _;
    }

    constructor() public {
        owner = msg.sender;
        recovery = new Recovery(this);
    }
    function setRecovery(address _recovery) onlyOwner public {
        recovery = _recovery;
    }
    function setIPFSHash(string _ipfs_hash) onlyOwner public {
        ipfs_hash = _ipfs_hash;
    }
    function setContacts(address[] _contacts) onlyOwner public {
        Recovery recovery_c = Recovery(recovery);
        recovery_c.setContacts(_contacts);
    }
    function addRecovery(address _recovery, address _key) onlyOwner public {
        Recovery recovery_c = Recovery(_recovery);
        recovery_c.addRecovery(_key);
    }
    function transferOwner(address _owner) onlyOwnerOrRecovery public {
        owner = _owner;
    }
    function getDetails() view public returns 
            (address _owner, string _ipfs_hash, address _recovery) {
        _owner = owner;
        _ipfs_hash = ipfs_hash;
        _recovery = recovery;
    }
}