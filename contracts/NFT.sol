// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NwBTCNFT.sol";

contract NFT is ERC721, Ownable {
  
    address payable public _owner;

    mapping(address => bool) public airdrop;
    mapping(uint256 => Collection) public indexToCollection;
    mapping(uint256 => bool) hashToMinted;
    mapping(uint256 => uint256) tokenIdToHash;
    
    string public _baseURI = "https://";
    
    function setBaseURI(string memory _base) onlyOwner external {
        _baseURI = _base;
    }
   
    function setAirdrop( address addr ) external {
        airdrop[ addr ] = true;
    }
    
    function getAirdrop( address addr ) external returns(bool) {
        return airdrop[ addr ];
    }
    
    struct Collection {
        string name;
        uint256 start;
        uint256 amount;
        string[] urls;
    }
 
    Counters.Counter private _collection;
    Counters.Counter private tokenIds;
 
    constructor() ERC721("NFTS", "nfts+") {
  	    _owner = msg.sender;
    }
    
    function walletOfOwner(address _wallet)
        external
        view
        override
        returns (uint256[] memory ) 
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "The token does not exist");

        string memory svgString;
                         
        uint256 hash = tokenIdToHash[ _tokenId ];

        uint8 _energy = uint8( (hash>>24)&0xff );
        uint8 _voice = uint8( (hash>>32)&0xff );
        uint8 _heart = uint8( (hash>>40)&0xff );
        
        string memory metaString = string(
            abi.encodePacked(
                '"attributes":','{"voice":',
                    NFTLibrary.toString( _voice ),
                    ',"heart":',
                    NFTLibrary.toString( _heart ),
                    ',"energy":',
                    NFTLibrary.toString( _energy ), '}'
             ) );
        
        uint256 _season = hash & 0xff;
        uint256 _indexURL = ( ( hash >> 8 ) & 0xff ) % uint8( indexToCollection[ _season ].urls.length );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    NFTLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',indexToCollection[ _season ].name,' ',
                                        NFTLibrary.toString( num ),'/',
                                        NFTLibrary.toString( indexToCollection[ _season ].amount),
                                        '","description": "Freedom loving art", "image": "',
                                        _baseURI, indexToCollection[ _season ].urls[ _indexURL ],'",',
                                        metaString,"}"
                                )
                            )
                        )
                    )
                )
            );
    }

    uint256 public _price = 12000000000000000000;

    function setPrice( uint256 v) external onlyOwner {
        _price = v;
    }
    
    function getPrice() external override returns(uint256){
        return _price;
    }

    function canMint() external override returns (bool){
        return ( 0 < (( indexToBodyType[ _bodyCount.current() ].start + indexToBodyType[_bodyCount.current()].amount ) - _tokenIds.current()));
    }

    function getHash(uint256 season,  uint256 _t ,address _a , uint256 _c )
        internal view returns (uint256) {
        
        require(_c < 10);

        uint256 _hash = season;
        uint256 tmp;
        for (uint8 i = 1; i < 8; i++) {
            tmp = 
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            ( _c + i )
                        )
                    )
                ) % 0xFF;
            _hash |= uint256((tmp << ( i * 8 ) ));
        }
        return _hash;
    }

    function setArtwork( uint256 _amount, string memory _name, string[] memory _urls )
        external onlyOwner returns (uint256) {
        
        _collection.increment();
 
        Collection memory _struct = Collection({
            name : _name,
            start: _tokenIds.current(),
            amount: _amount,
            urls: _urls
        });

        indexToBodyType[ _collection.current() ] = _struct;
        return _collection.current();
    }

  function mint(string memory _tokenURI) external onlyOwner {
    require( ( indexToCollection[ _collection.current() ].start + indexToCollection[ _collection.current() ].amount )  > (_tokenIds.current() + 1) , "Season has ended");
        require(_collection.current() > 0, "No default art");
        
        if ( airdrop[ msg.sender ] ) airdrop[ msg.sender ] = false;
        else {
            require( _nwBTCToken.allowance( msg.sender, address(this) ) >= _price,"Insuficient Allowance");
            require(_nwBTCToken.transferFrom(msg.sender,_stakeAddress,_price),"transfer Failed");
        }
        _tokenIds.increment();
        uint256 thisTokenId = _tokenIds.current();

        tokenIdToHash[ _tokenIds.current() ] = getHash( _collection.current() , _tokenIds.current(), msg.sender, 0);
        hashToMinted[ tokenIdToHash[ _tokenIds.current() ] ] = true;
        _mint(msg.sender, _tokenIds.current());
  }
}
