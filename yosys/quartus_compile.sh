#!/bin/env bash
set -e

quartus_map -c ir_yosys top
quartus_fit -c ir_yosys top
quartus_asm -c ir_yosys top
