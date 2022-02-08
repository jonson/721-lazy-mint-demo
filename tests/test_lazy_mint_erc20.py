import pytest
from brownie import accounts, network, WETH9, LazyMint721ERC20Payment
from eip712.messages import EIP712Message, EIP712Type

from tests.voucher import create_voucher, to_struct


@pytest.fixture(scope="module")
def deployer():
    local = accounts.add()
    accounts[0].transfer(local, "10 ether", gas_price=0)
    return local


@pytest.fixture()
def weth(deployer):
    return deployer.deploy(WETH9)


@pytest.fixture
def lazy_mint(deployer):
    return deployer.deploy(LazyMint721ERC20Payment, "Lazy", "MINT")


def test_mint_with_voucher_native(deployer, weth, lazy_mint):
    platform_wallet = accounts[4].address
    seller_wallet = accounts[5].address

    # 2.5%
    platform_cut = 250

    assert lazy_mint.balanceOf(accounts[1].address) == 0
    assert weth.balanceOf(platform_wallet) == 0
    assert weth.balanceOf(seller_wallet) == 0

    voucher = create_voucher(lazy_mint.address, 1, 1000, weth.address, platform_cut, platform_wallet, seller_wallet)
    signed = deployer.sign_message(voucher)
    lazy_mint.mintWithVoucherNative(to_struct(voucher), signed.signature, {'value': voucher.price, 'from': accounts[1]})

    assert lazy_mint.balanceOf(accounts[1].address) == 1
    assert weth.balanceOf(platform_wallet) == 25
    assert weth.balanceOf(seller_wallet) == 975


def test_mint_with_voucher_erc20(deployer, weth, lazy_mint):
    platform_wallet = accounts[4].address
    seller_wallet = accounts[5].address

    # 2.5%
    platform_cut = 250

    assert lazy_mint.balanceOf(accounts[1].address) == 0
    assert weth.balanceOf(platform_wallet) == 0
    assert weth.balanceOf(seller_wallet) == 0

    weth.deposit({'value': 1000, 'from': accounts[1]})
    weth.approve(lazy_mint.address, 1000, {'from': accounts[1]})

    voucher = create_voucher(lazy_mint.address, 1, 1000, weth.address, platform_cut, platform_wallet, seller_wallet)
    signed = deployer.sign_message(voucher)
    lazy_mint.mintWithVoucher(to_struct(voucher), signed.signature, {'from': accounts[1]})

    assert lazy_mint.balanceOf(accounts[1].address) == 1
    assert weth.balanceOf(platform_wallet) == 25
    assert weth.balanceOf(seller_wallet) == 975
