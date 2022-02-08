import pytest
from brownie import accounts, LazyMint721EthPayment, ZERO_ADDRESS

from .voucher import create_voucher, to_struct


@pytest.fixture
def lazy_mint(deployer):
    return deployer.deploy(LazyMint721EthPayment, "Lazy", "MINT")


def test_mint_with_voucher_happy_path(deployer, lazy_mint):
    platform_wallet = accounts[4].address
    seller_wallet = accounts[5].address

    # 2.5%
    platform_cut = 250

    assert lazy_mint.balanceOf(accounts[1].address) == 0
    assert lazy_mint.payments(platform_wallet) == 0
    assert lazy_mint.payments(seller_wallet) == 0

    voucher = create_voucher(lazy_mint.address, 1, 1000, ZERO_ADDRESS, platform_cut, platform_wallet, seller_wallet)
    signed = deployer.sign_message(voucher)
    lazy_mint.mintWithVoucher(to_struct(voucher), signed.signature, {'value': voucher.price, 'from': accounts[1]})

    assert lazy_mint.balanceOf(accounts[1].address) == 1
    assert lazy_mint.payments(platform_wallet) == 25
    assert lazy_mint.payments(seller_wallet) == 975
    assert lazy_mint.tokenURI(1) == 'ipfs://QmbbkKsdJU8toiRLpdBayz93CMnjZf6GuCgRHJ153oUxcX'