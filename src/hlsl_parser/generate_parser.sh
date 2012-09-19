#!/bin/bash

java -Xmx512M -cp ../../contrib/antlr.jar org.antlr.Tool -report -Xwatchconversion HLSL.g
