#!/usr/bin/env bats

load test_helper

setup() {
  create_app
}

teardown() {
  rm -rf /home/dokku/$TEST_APP/tls /home/dokku/tls
  destroy_app
}

assert_urls() {
  urls=$@
  run dokku urls $TEST_APP
  echo "output: "$output
  echo "status: "$status
  assert_output < <(tr ' ' '\n' <<< "${urls}")
}

build_nginx_config() {
  # simulate nginx post-deploy
  dokku domains:setup $TEST_APP
  dokku nginx:build-config $TEST_APP
}

@test "(core) remove exited containers" {
  deploy_app
  # make sure we have many exited containers of the same 'type'
  run bash -c "for cnt in 1 2 3; do dokku run $TEST_APP hostname; done"
  echo "output: "$output
  echo "status: "$status
  assert_success
  run bash -c "docker ps -a -f 'status=exited' --no-trunc=false | grep '/exec hostname'"
  echo "output: "$output
  echo "status: "$status
  assert_success
  run dokku cleanup
  echo "output: "$output
  echo "status: "$status
  assert_success
  sleep 5  # wait for dokku cleanup to happen in the background
  run bash -c "docker ps -a -f 'status=exited' --no-trunc=false | grep '/exec hostname'"
  echo "output: "$output
  echo "status: "$status
  assert_failure
  run bash -c "docker ps -a -f 'status=exited' -q --no-trunc=false"
  echo "output: "$output
  echo "status: "$status
  assert_output ""
}

@test "(core) run (with tty)" {
  deploy_app
  run /bin/bash -c "dokku run $TEST_APP ls /app/package.json"
  echo "output: "$output
  echo "status: "$status
  assert_success
}

@test "(core) run (without tty)" {
  deploy_app
  run /bin/bash -c ": |dokku run $TEST_APP ls /app/package.json"
  echo "output: "$output
  echo "status: "$status
  assert_success
}

