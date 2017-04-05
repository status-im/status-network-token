#! /bin/bash

output=$(nc -z localhost 8546; echo $?)
[ $output -eq "0" ] && trpc_running=true
if [ ! $trpc_running ]; then
  echo "Starting our own testrpc node instance"
  testrpc -l 100000000 -i 15 -p 8546 > /dev/null &
  trpc_pid=$!
fi
./node_modules/truffle/cli.js test --network development46 test/TestTokenSale.sol
./node_modules/truffle/cli.js test --network development46 test/TestTokenPresale.sol
./node_modules/truffle/cli.js test --network development46 test/helpers/* test/*.js
if [ ! $trpc_running ]; then
  kill -9 $trpc_pid
fi
