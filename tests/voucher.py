from eip712.messages import EIP712Message
from brownie import accounts, network


class NFTVoucher(EIP712Message):
    _name_: "string" = "Voucher"
    _version_: "string" = "1"
    _chainId_: "uint256"  # type: ignore # noqa: F821
    _verifyingContract_: "address"  # type: ignore # noqa: F821

    tokenId: "uint256"
    price: "uint256"
    currency: "address"
    cid: "string"

    minter: "address"
    expiresAt: "uint256"

    primaryRecipientBips: "uint256"
    primaryRecipient: "address"
    remainderRecipient: "address"


def to_struct(voucher):
    return (
        voucher.tokenId,
        voucher.price,
        voucher.currency,
        voucher.cid,
        voucher.minter,
        voucher.expiresAt,
        voucher.primaryRecipientBips,
        voucher.primaryRecipient,
        voucher.remainderRecipient
    )


def create_voucher(lazy_mint_address, token_id: int, price: int, currency, primary_bips, primary_recipient, remainder_recipient, cid="QmbbkKsdJU8toiRLpdBayz93CMnjZf6GuCgRHJ153oUxcX", minter=None):
    if not minter:
        minter = accounts[1].address
    return NFTVoucher(
        _chainId_=network.chain.id,
        _verifyingContract_=lazy_mint_address,

        tokenId=token_id,
        price=price,
        currency=currency,
        cid=cid,
        minter=minter,
        expiresAt=0,
        primaryRecipientBips=primary_bips,
        primaryRecipient=primary_recipient,
        remainderRecipient=remainder_recipient,
    )
