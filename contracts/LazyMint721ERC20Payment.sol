// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interfaces/IWrapped.sol";
import "./LazyMintSupport.sol";

/**
 * - Lazy minting via a EIP712 voucher struct signed by owner.
 * - All payments done in ERC20s defined in voucher.
 * - Automatically wraps native currency (eth).
 * - Vouchers have an optional expiration.
 * - Push payment to recipients as part of mint.
 */
contract LazyMint721ERC20Payment is
    ERC721URIStorage,
    Ownable,
    EIP712,
    LazyMintSupport
{
    using SafeERC20 for IERC20;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        EIP712("Voucher", "1")
    {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function mintWithVoucherNative(
        NFTVoucher calldata voucher,
        bytes calldata signature
    ) external payable {
        // verify signature
        address signer = _verify(voucher, signature);
        require(signer == owner(), "Invalid signer");
        require(msg.value == voucher.price, "Invalid amount");

        IWRAPPED(voucher.currency).deposit{value: msg.value}();
        _mintWithVoucher(voucher, msg.sender, address(this));
    }

    function mintWithVoucher(
        NFTVoucher calldata voucher,
        bytes calldata signature
    ) external {
        // verify signature
        address signer = _verify(voucher, signature);
        require(signer == owner(), "Invalid signer");

        _baseURI();

        _mintWithVoucher(voucher, msg.sender, msg.sender);
    }

    function _mintWithVoucher(
        NFTVoucher memory voucher,
        address toAddress,
        address payer
    ) private {
        require(
            voucher.primaryRecipientBips > 0 &&
                voucher.primaryRecipientBips <= 10_000,
            "Invalid Bips"
        );
        require(
            voucher.primaryRecipient != address(0),
            "Invalid primary recipient"
        );

        IERC20 currency = IERC20(voucher.currency);

        // transfer funds
        if (voucher.primaryRecipientBips == 10_000) {
            currency.safeTransferFrom(
                payer,
                voucher.primaryRecipient,
                voucher.price
            );
        } else {
            require(
                voucher.remainderRecipient != address(0),
                "Invalid remainder recipient"
            );
            // transfer funds
            uint256 primaryAmount = (voucher.price *
                voucher.primaryRecipientBips) / 10_000;

            currency.safeTransferFrom(
                payer,
                voucher.primaryRecipient,
                primaryAmount
            );
            currency.safeTransferFrom(
                payer,
                voucher.remainderRecipient,
                voucher.price - primaryAmount
            );
        }

        // mint token
        _mint(toAddress, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.cid);
    }
}
