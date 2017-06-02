#!/bin/bash
export POD_SPEC_LINT_MODE="$1"
pod spec lint --allow-warnings SCFFLD.podspec
