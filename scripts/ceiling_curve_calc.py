#!/usr/bin/env python3
''' Calculate ceiling characteristics based on curve parameters '''


import argparse
import decimal
from decimal import Decimal
import math
import statistics
from typing import List, Sequence


decimal.getcontext().rounding = decimal.ROUND_DOWN


def args_parse(arguments: Sequence[str] = None) -> argparse.Namespace:
    ''' Parse arguments '''
    par0 = argparse.ArgumentParser(
        description='Calculate ceiling characteristics based on curve parameters')

    # Required
    par0.add_argument('--limit', metavar='LIMIT', required=True, type=Decimal,
                      help='Ceiling limit')
    par0.add_argument('--curve-factor', metavar='FACTOR', required=True, type=Decimal,
                      help='Curve factor')
    # Optional
    par0.add_argument('--collected-start', metavar='WEI', type=Decimal,
                      default=Decimal('0'), help='Amount collected at start of curve')
    par0.add_argument('--gas-per-tx', metavar='AMOUNT', type=Decimal,
                      default=Decimal('71429'), help='Gas used per transaction')
    par0.add_argument('--gas-price', metavar='WEI', type=Decimal,
                      default=Decimal('50000000000'), help='Gas price')
    par0.add_argument('--fee-token', metavar='FRACTION', type=Decimal,
                      default=Decimal('0.1'), help='Fee cost as fraction of token value')
    par0.add_argument('--collect-min', metavar='WEI', type=Decimal,
                      help='Minimum collection amount')
    par0.add_argument('--gas-limit', metavar='AMOUNT', type=Decimal,
                      default=Decimal('4700000'), help='Gas limit per block')
    par0.add_argument('--secs-per-block', metavar='SECONDS', type=Decimal,
                      default=Decimal('16.4'), help='Average seconds per block')
    par0.add_argument('--print-txs', action='store_true',
                      default=False, help='Print every individual transaction')

    args0 = par0.parse_args(arguments)
    return args0


def transactions_calc(
        limit: Decimal,
        curve_factor: Decimal,
        collect_minimum: Decimal,
        collected_start: Decimal = Decimal(0),
) -> List[Decimal]:
    ''' Calculate transactions '''
    collected = collected_start
    transactions = []
    while True:
        difference = limit - collected
        to_collect = difference / curve_factor

        if to_collect <= collect_minimum:
            if difference > collect_minimum:
                to_collect = collect_minimum
            else:
                to_collect = difference

        collected += to_collect
        transactions.append(to_collect)

        if collected >= limit:
            break

    return transactions


def fmt_wei(value: Decimal, shift: bool = False) -> str:
    ''' Format wei value '''
    fmt_val = f'{value:.0f}'
    if shift:
        return f'{"w" + fmt_val: >26}'  # type: ignore
    return f'{"w" + fmt_val}'  # type: ignore


def fmt_eth(value: Decimal, shift: bool = False) -> str:
    ''' Format wei value into ether '''
    fmt_val = f'{value / 10**18:.18f}'
    if shift:
        return f'{"Ξ" + fmt_val: >26}'  # type: ignore
    return f'{"Ξ" + fmt_val}'  # type: ignore


def main() -> None:
    ''' Main '''
    tx_fee = ARGS.gas_per_tx * ARGS.gas_price
    tx_token_fee = tx_fee / ARGS.fee_token
    collect_min = ARGS.collect_min if ARGS.collect_min is not None else tx_token_fee

    transactions = transactions_calc(
        ARGS.limit,
        ARGS.curve_factor,
        collect_min,
        collected_start=ARGS.collected_start,
    )

    collect_fee_total = 0
    collect_minimum_total = 0
    for n, transaction in enumerate(transactions):
        if transaction <= collect_min:
            collect_minimum_total += 1

        if transaction < tx_token_fee:
            collect_fee_total += 1

        if ARGS.print_txs:
            print(f'{(n + 1): >4}: {fmt_wei(transaction, shift=True)} '
                  f' {fmt_eth(transaction, shift=True)}')
    print()

    print(f'Token fee: {fmt_wei(tx_token_fee)} {fmt_eth(tx_token_fee)}')
    transactions_len = len(transactions)
    print(f'Number of transactions: {transactions_len}')
    print(f'Number of transactions <= collectMinimum: {collect_minimum_total}')
    print(f'Number of transactions < token fee: {collect_fee_total}')

    average = statistics.mean(transactions)
    print(f'Average contribution: {fmt_wei(average)} {fmt_eth(average)}')
    median = statistics.median(transactions)
    print(f'Median contribution: {fmt_wei(median)} {fmt_eth(median)}')

    decimal.getcontext().rounding = decimal.ROUND_HALF_EVEN
    blocks = math.ceil((transactions_len * ARGS.gas_per_tx) / ARGS.gas_limit)
    print(f'Minimum blocks for curve: {blocks}')
    print(f'Minimum time for curve: {blocks * ARGS.secs_per_block:.2f}s')
    decimal.getcontext().rounding = decimal.ROUND_DOWN


if __name__ == '__main__':
    ARGS = args_parse()
    main()
