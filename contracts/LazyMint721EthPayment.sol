// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./LazyMintSupport.sol";

/**
 * - Lazy minting via a EIP712 voucher struct signed by owner.
 * - All payments must be made in eth.
 * - Vouchers have an optional expiration.
 * - Pull payment for recipients.
 * - IPFS metadata storage
 */
contract LazyMint721EthPayment is
    ERC721URIStorage,
    Ownable,
    EIP712,
    PullPayment,
    LazyMintSupport
{
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        EIP712("Voucher", "1")
    {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function mintWithVoucher(
        NFTVoucher calldata voucher,
        bytes calldata signature
    ) external payable {
        // verify signature
        address signer = _verify(voucher, signature);
        require(signer == owner(), "Invalid signer");
        require(voucher.currency == address(0));

        _mintWithVoucher(voucher, msg.sender);
    }

    function _mintWithVoucher(NFTVoucher memory voucher, address toAddress)
        private
    {
        require(
            voucher.primaryRecipientBips > 0 &&
                voucher.primaryRecipientBips <= 10_000,
            "Invalid Bips"
        );
        require(
            voucher.primaryRecipient != address(0),
            "Invalid primary recipient"
        );
        require(msg.value == voucher.price, "Invalid price");

        // transfer funds
        if (voucher.primaryRecipientBips == 10_000) {
            _asyncTransfer(voucher.primaryRecipient, voucher.price);
        } else {
            require(
                voucher.remainderRecipient != address(0),
                "Invalid remainder recipient"
            );
            // transfer funds
            uint256 primaryAmount = (voucher.price *
                voucher.primaryRecipientBips) / 10_000;

            _asyncTransfer(voucher.primaryRecipient, primaryAmount);
            _asyncTransfer(
                voucher.remainderRecipient,
                voucher.price - primaryAmount
            );
        }

        // mint token
        _mint(toAddress, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.cid);
    }
}
