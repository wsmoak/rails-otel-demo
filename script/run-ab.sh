#!/bin/bash

REQUESTS=100
CONCURRENCY=10
URL="http://localhost:3001/customers"

# Run Apache Bench
ab -n $REQUESTS -c $CONCURRENCY $URL