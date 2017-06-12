#!/usr/bin/env python3
''' Calculate ceiling characteristics based on curve parameters '''


import argparse
import decimal
from decimal import Decimal
import statistics
from typing import List, Sequence, Tuple


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
    par0.add_argument('--collect-min', metavar='MINIMUM', required=True, type=Decimal,
                      help='Minimum collection amount')

    args0 = par0.parse_args(arguments)
    return args0


def transactions_calc(limit: Decimal, curve_factor: Decimal,
                      collect_minimum: Decimal) -> Tuple[List[Decimal], int]:
    ''' Calculate transactions '''
    collected = Decimal(0)
    transactions = []
    collect_minimum_total = 0
    while True:
        difference = limit - collected
        to_collect = difference / curve_factor

        if to_collect <= collect_minimum:
            collect_minimum_total += 1
            if difference > collect_minimum:
                to_collect = collect_minimum
            else:
                to_collect = difference

        collected += to_collect
        transactions.append(to_collect)

        if collected >= limit:
            break

    return transactions, collect_minimum_total


def main() -> None:
    ''' Main '''
    transactions, collect_minimum_total = transactions_calc(
        ARGS.limit, ARGS.curve_factor, ARGS.collect_min)

    for n, transaction in enumerate(transactions):
        print(f'{n: >4}: {transaction:.0f}')
    print()

    print(f'Number of transactions: {len(transactions)}')
    print(f'Number of transactions <= collectMinimum: {collect_minimum_total}')
    print(f'Average contribution: {statistics.mean(transactions):.0f}')
    print(f'Median contribution: {statistics.median(transactions):.0f}')


if __name__ == '__main__':
    ARGS = args_parse()
    main()
