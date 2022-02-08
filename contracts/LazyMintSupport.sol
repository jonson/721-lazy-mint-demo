pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract LazyMintSupport is EIP712 {
    bytes32 internal constant VOUCHER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "NFTVoucher(uint256 tokenId,uint256 price,address currency,string cid,address minter,uint256 expiresAt,uint256 primaryRecipientBips,address primaryRecipient,address remainderRecipient)"
            )
        );

    struct NFTVoucher {
        uint256 tokenId;
        uint256 price;
        address currency;
        string cid; // ipfs cid, without the ipfs:// prefix
        address minter;
        uint256 expiresAt;
        uint256 primaryRecipientBips;
        address primaryRecipient;
        address remainderRecipient;
    }

    function _verify(NFTVoucher calldata voucher, bytes calldata signature)
        internal
        view
        returns (address)
    {
        require(msg.sender == voucher.minter, "Invalid minter");
        require(bytes(voucher.cid).length > 0, "Missing cid");
        if (voucher.expiresAt > 0) {
            require(voucher.expiresAt < block.timestamp, "Voucher expired");
        }
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, signature);
    }

    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        VOUCHER_TYPEHASH,
                        voucher.tokenId,
                        voucher.price,
                        voucher.currency,
                        keccak256(bytes(voucher.cid)),
                        voucher.minter,
                        voucher.expiresAt,
                        voucher.primaryRecipientBips,
                        voucher.primaryRecipient,
                        voucher.remainderRecipient
                    )
                )
            );
    }
}
